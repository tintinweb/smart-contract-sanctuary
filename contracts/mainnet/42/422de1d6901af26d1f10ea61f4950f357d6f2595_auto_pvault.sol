/**
 *Submitted for verification at Etherscan.io on 2021-03-22
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IERC20 {
    function totalSupply() external view returns (uint);
    function balanceOf(address account) external view returns (uint);
    function transfer(address recipient, uint amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint);
    function approve(address spender, uint amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IUniswapV2Pair {
    function sync() external;
}

interface UniswapRouter {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function swapExactTokensForTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external returns (uint[] memory);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline) external returns (uint[] memory amounts);
    function addLiquidityETH(address token,uint amountTokenDesired,uint amountTokenMin,uint amountETHMin,address to,uint deadline) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function addLiquidity(address tokenA, address tokenB, uint amountADesired, uint amountBDesired, uint amountAMin, uint amountBMin, address to, uint deadline) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function getAmountsOut(uint amountIn, address[] memory path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] memory path) external view returns (uint[] memory amounts);
}

interface IPVault {
    function deposit(uint256 amount) external;
    function claimReward(uint256 amount) external;
    function claimRewardAll() external;
    function withdraw(uint256 amount) external;
}

interface YCrvGauge {
    function deposit(uint256 amount) external;
    function withdraw(uint256 amount) external;
    function integrate_fraction(address account) external view returns (uint256);
    function user_checkpoint(address account) external returns (bool);
    function crv_token() external view returns (address);
    function controller() external view returns (address);
    function period() external view returns (uint256);
    function period_timestamp(uint256 amount) external view returns (uint256);
    function integrate_inv_supply(uint256 amount) external view returns (uint256);
    function integrate_inv_supply_of(address account) external view returns (uint256);
    function inflation_rate() external view returns (uint256);
    function future_epoch_time() external view returns (uint256);
    function working_balances(address account) external view returns (uint256);
    function working_supply() external view returns (uint256);
}

interface Controller {
    function gauge_relative_weight(address account, uint256 time) external view returns (uint256);
}

interface CRV20 {
    function rate() external view returns (uint256);
}

interface TokenMinter {
    function mint(address account) external;
    function minted(address account, address guage) external view returns (uint256);
}

interface IUniswapV2ERC20 {
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
}

contract auto_pvault {

    IERC20 constant WETH = IERC20(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    UniswapRouter constant UNIROUTER = UniswapRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    IUniswapV2ERC20 constant LPT = IUniswapV2ERC20(0xBe9Ba93515e87C7Bd3A0CEbB9f61AAabE7A77Dd3);
    YCrvGauge constant YCRVGAUGE = YCrvGauge(0xFA712EE4788C042e2B7BB55E6cb8ec569C4530c1);
    TokenMinter constant TOKENMINTER = TokenMinter(0xd061D61a4d941c39E5453435B6345Dc261C2fcE0);
    IERC20 constant CRV = IERC20(0xD533a949740bb3306d119CC777fa900bA034cd52);

    IERC20 public token0;
    IERC20 public token1;
    IPVault public pvault;

    address public feeAddress;
    address public treasury;
    address public gov;
    address[] internal stakeholders;

    string public vaultName;
    uint32 constant TOTALRATE = 10000;
    uint32 public feeRate;
    uint32 public rewardUserRate = 7000;
    uint32 public rewardTreasuryRate = 3000;
    uint32 public gasRewardTreasuryRate = 7000;
    uint32 public pvault_rate = 2000;
    uint256 constant WEEK = 604800;
    uint256 public address_array_len;
    uint256 constant TOTALWETHRATE = 10000000000;
    uint256 constant TOTALUSERWETHSHARE = 5384615385;
    uint256 public timestamp_block;
    uint256 public max;
    uint256 public finalP;
    uint256 public finalW;
    uint256 public finalLPT;
    uint256 public delayDuration = 1 days;

    event yCRVDeposited(address indexed user, uint amount);
    event AllRewardsClaimed(address indexed user, uint amount, uint amount2);
    event WithdrawnAndAllRewardsClaimed(address indexed user, uint amount, uint amount2, uint amount3);
    event AutoCompoundedCRV2PVAULT(address indexed user, uint amount);
    event MassAutoCompoundedCRV2PVAULT(address indexed user, uint amount);

    struct User {
        uint256 rewardedBalancePerUser; // CRV
        uint256 lastTimestampPerUser; 
        uint256 depositBalancePerUser;  // in yCRV
        uint256 accDepositBalancePerUser; // in yCRV
        uint256 lpTokenUserReward; // LP Token
        uint256 userRewardProportion; // Proportion entitled to based on user's deposit in relation to total deposits
        uint256 massClaimReward;
        uint256 rewardedPYLON;
    }

    struct Global {
        uint256 lastTotalTimestamp;
        uint256 accTotalReward;
        uint256 totalDeposit;
        uint256 accTotalDeposit;
        uint256 totalDepositForAPY;
        uint256 lpTokenReward;
        uint256 userCount;
        uint256 lpTotalDeposit;
        uint256 lastMassDrainTimestamp;
        uint256 totalPYLON;
        bool isEligibleI;
    }

    struct vals {
        uint256 pylonAmount;
        uint256 wethUser;
        uint256 lpAmount;  
        uint256 wethSent;
        uint256 pylonSent;
        uint256 pylonNeeded;
        uint256 wethNeeded;
        uint256 crvNeeded4Reward;
        uint256 gasRewardTreasury;
        uint256 finalLPTsent;
        uint256 crv4LP;
        uint256 crvFromGauge;
        uint256 crv4pylonLP;
        uint256 crv4wethLP;
    }

    // gas price is in wei
    struct vespiangas {
        uint getRewardGas;
        uint getRewardGasPrice;
    }

    mapping(address => User) public user_; 
    mapping(uint256 => Global) public global_;
    mapping(uint256 => vals) public vals_;
    mapping(uint256 => vespiangas) public gas_;

    constructor (address _token0, address _token1, address _feeAddress, address _pvault, string memory name, address _treasury) payable {
        token0 = IERC20(_token0);
        token1 = IERC20(_token1);
        feeAddress = _feeAddress;
        pvault = IPVault(_pvault);
        vaultName = name;
        gov = msg.sender;
        treasury = _treasury;
        token0.approve(address(YCRVGAUGE), type(uint).max);
        CRV.approve(address(UNIROUTER), type(uint).max);
        CRV.approve(address(this), type(uint).max);
        WETH.approve(address(UNIROUTER), type(uint).max);
        token1.approve(address(UNIROUTER), type(uint).max);
        token1.approve(address(this), type(uint).max);
        WETH.approve(address(this), type(uint).max);
        WETH.approve(address(LPT), type(uint).max);
        token1.approve(address(LPT), type(uint).max);
        LPT.approve(address(this), type(uint).max);
    }

    modifier onlyGov() {
        require(msg.sender == gov, "!governance");
        _;
    }

    function isStakeholder(address _address) public view returns(bool, uint256) {
        for (uint256 s = 0; s < stakeholders.length; s += 1){
            if (_address == stakeholders[s]) return (true, s);
        }
        return (false, 0);
    }

    function isMassDrainEligible() internal returns (bool){
        
        bool result;
        
        // if first time calling this function via massAutoCompoundCRV2PVAULT then global_[0].lastMassDrainTimestamp
        // will be assigned as the current timestamp and return false since 24 hours likely hasn't passed.
        if (global_[0].lastMassDrainTimestamp == 0) {
            global_[0].lastMassDrainTimestamp = block.timestamp;
            result = false;
        }
        else if (global_[0].lastMassDrainTimestamp + delayDuration > block.timestamp) {
            result = false; // last time was called + 24 hours is larger than current time, so 24 hours hasn't passed
        }
        else {
            result = true;
        }
        global_[0].isEligibleI = result;
        return (result);
    }

    function isEligibleExternal() external returns (bool){
        
        bool result;
        
        // if first time calling this function via massAutoCompoundCRV2PVAULT then global_[0].lastMassDrainTimestamp
        // will be assigned as the current timestamp and return false since 24 hours likely hasn't passed.
        if (global_[0].lastMassDrainTimestamp == 0) {
            global_[0].lastMassDrainTimestamp = block.timestamp;
            result = false;
        }
        else if (global_[0].lastMassDrainTimestamp + delayDuration > block.timestamp) {
            result = false; // last time was called + 24 hours is larger than current time, so 24 hours hasn't passed
        }
        else {
            result = true;
        }
        global_[0].isEligibleI = result;
        return (result);
    }
    
    // don't need to call this on main net test if the isEligibleExternal function is called first
    function setMassTS() external {
        if (global_[0].lastMassDrainTimestamp == 0) {
            global_[0].lastMassDrainTimestamp = block.timestamp;
        }
    }

    function addStakeholder(address _stakeholder) public {
        (bool _isStakeholder, ) = isStakeholder(_stakeholder);
        if(!_isStakeholder) stakeholders.push(_stakeholder);
    }

    function removeStakeholder(address _stakeholder) public {
        (bool _isStakeholder, uint256 s) = isStakeholder(_stakeholder);
        if(_isStakeholder){
            stakeholders[s] = stakeholders[stakeholders.length - 1];
            stakeholders.pop();
        }
    }

    modifier updateBalance(address userAddress) {
        uint lastTimestamp = user_[userAddress].lastTimestampPerUser;
        uint totalTimestamp = global_[0].lastTotalTimestamp;
        if (lastTimestamp > 0) {
            user_[userAddress].accDepositBalancePerUser += user_[userAddress].depositBalancePerUser * (block.timestamp - lastTimestamp);
        }

        if (totalTimestamp > 0) {
            global_[0].accTotalDeposit += global_[0].totalDeposit * (block.timestamp - totalTimestamp);
        }
        user_[userAddress].lastTimestampPerUser = block.timestamp;
        global_[0].lastTotalTimestamp = block.timestamp;
        _;
    }

    modifier updateBalanceAllUsers() {

        uint totalTimestamp = global_[0].lastTotalTimestamp;

        // userCount is updated when someone deposits or withdraws
        for (uint i=0; i < global_[0].userCount ; i += 1){

            address ua = stakeholders[i];

            uint lastTimestamp = user_[ua].lastTimestampPerUser;

            if (lastTimestamp > 0) {
                user_[ua].accDepositBalancePerUser += user_[ua].depositBalancePerUser * (block.timestamp - lastTimestamp);
            }

            user_[ua].lastTimestampPerUser = block.timestamp;
        }

        if (totalTimestamp > 0) {
            global_[0].accTotalDeposit += global_[0].totalDeposit * (block.timestamp - totalTimestamp);
        }
        global_[0].lastTotalTimestamp = block.timestamp; 
        _;
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        if (a > b) {
            return b;
        }
        else {
            return a;
        }
    }

    function setGovernance(address _gov)
        external
        onlyGov
    {
        gov = _gov;
    }

    function setToken0(address _token)
        external
        onlyGov
    {
        token0 = IERC20(_token);
    }

    function setToken1(address _token)
        external
        onlyGov
    {
        token1 = IERC20(_token);
    }

    function setTreasury(address _treasury)
        external
        onlyGov
    {
        treasury = _treasury;
    }

    function setUserRate(uint32 _rewardUserRate)
        external
        onlyGov
    {
        rewardUserRate = _rewardUserRate;
    }

    function setTreasuryRate(uint32 _rewardTreasuryRate)
        external
        onlyGov
    {
        rewardTreasuryRate = _rewardTreasuryRate;
    }

    function setFeeAddress(address _feeAddress)
        external
        onlyGov
    {
        feeAddress = _feeAddress;
    }

    function setFeeRate(uint32 _feeRate)
        external
        onlyGov
    {
        feeRate = _feeRate;
    }

    function setVaultName(string memory name)
        external
        onlyGov
    {
        vaultName = name;
    }

    function getRewardI() internal {

        uint256 rewardAmountForCRVToken = CRV.balanceOf(address(this));
        TOKENMINTER.mint(address(YCRVGAUGE));
        rewardAmountForCRVToken = CRV.balanceOf(address(this)) - rewardAmountForCRVToken;
        uint256 rewardCRVTokenAmountForUsers = rewardAmountForCRVToken * rewardUserRate / TOTALRATE;
        uint256 rewardCRVTokenAmountForTreasury = rewardAmountForCRVToken - rewardCRVTokenAmountForUsers; // 30% of reward goes to treasur

        uint256 rewardPylonTokenAmountForUsers = token1.balanceOf(address(this));
        
        // apportion respective amounts to be made into ETH-PYLON LP Token
        uint256 AmountForUsersCRV2PYLON = rewardCRVTokenAmountForUsers / 2; // 50% of the 70% will be converted to Pylon
        uint256 amountForUsersCRV2WETH = rewardCRVTokenAmountForUsers / 2; // other 50% of the 70% will be converted to WET
        
        // combine the 50% CRV for user and 30% CRV for treasury so that only one call is made to convert CRV to WETH, will apportion returned WETH correctly below
        uint256 totalCrv2WethReward = amountForUsersCRV2WETH + rewardCRVTokenAmountForTreasury;

        address[] memory tokens = new address[](3);
        address[] memory tokens1 = new address[](2);

        tokens[0] = address(CRV);
        tokens[1] = address(WETH);
        tokens[2] = address(token1);
        tokens1[0] = address(CRV);
        tokens1[1] = address(WETH);

        if (rewardCRVTokenAmountForUsers > 0) {
            UNIROUTER.swapExactTokensForTokens(AmountForUsersCRV2PYLON, 0, tokens, address(this), type(uint).max);
        }

        uint256 wethBalance = WETH.balanceOf(address(this));
        if (totalCrv2WethReward > 0) {
            UNIROUTER.swapExactTokensForTokens(totalCrv2WethReward, 0, tokens1, address(this), type(uint).max);
        }

        wethBalance = WETH.balanceOf(address(this)) - wethBalance;

        // lpWETH gets set to the proportion of WETH to go to users (that will be used in LP token creation)
        uint256 lpWETH = wethBalance * TOTALUSERWETHSHARE / TOTALWETHRATE; // rougly 54% of WETH returned from CRV 2 WETH swap will go to LP token creation
        vals_[0].wethUser = lpWETH;
        uint256 treasuryWETH = wethBalance - lpWETH; // remaining ~46% of CRV 2 WETH swap goes to treasury

        // Pylon amount to be combined with WETH to make LP Token
        vals_[0].pylonAmount += token1.balanceOf(address(this)) - rewardPylonTokenAmountForUsers;

        // Transfer reward to Treasury
        if (treasuryWETH > 0) {
            WETH.transfer(treasury, treasuryWETH);
        }

        addLiquidityAndStakeI();

    }

    function assessGasV2() internal {
        
        address[] memory tokens1 = new address[](2);
        tokens1[0] = address(CRV);
        tokens1[1] = address(WETH);

        uint256 wethBalance = WETH.balanceOf(address(this));
        uint256 crvRewardNeeded4swap = vals_[0].crvNeeded4Reward;
        if (crvRewardNeeded4swap > 0) {
            UNIROUTER.swapExactTokensForTokens(crvRewardNeeded4swap, 0, tokens1, address(this), type(uint).max);
        }

        wethBalance = WETH.balanceOf(address(this)) - wethBalance;

        uint256 gasRewardTreasury = wethBalance * gasRewardTreasuryRate / TOTALRATE;
        vals_[0].gasRewardTreasury = gasRewardTreasury; // will combine with weth reward for treasury in getRewardAllI()
        
        uint256 userMassGasReward  = wethBalance - gasRewardTreasury;
        user_[msg.sender].massClaimReward = userMassGasReward;

        // Transfer gas reward to user
        if (userMassGasReward > 0) {
            WETH.transfer(msg.sender, userMassGasReward);
        }

        // Transfer gas Reward to Treasury
        if (gasRewardTreasury > 0) {
            WETH.transfer(treasury, gasRewardTreasury);
        }
    }
    
    function getRewardAll() internal {

        TOKENMINTER.mint(address(YCRVGAUGE));
        uint256 rewardAmountForCRVToken = CRV.balanceOf(address(this));
        vals_[0].crvFromGauge = rewardAmountForCRVToken;

        uint256 numUsers = global_[0].userCount - 1; // subtracting 1 since the user calling shouldn't be included in calculation
        
        uint256 getRewardGasWei = 479470 * numUsers * tx.gasprice;
        gas_[0].getRewardGas = getRewardGasWei;
        //gas_[0].getRewardGasPrice = tx.gasprice;

        address[] memory tokens = new address[](3);
        address[] memory tokens1 = new address[](2);

        tokens[0] = address(CRV);
        tokens[1] = address(WETH);
        tokens[2] = address(token1);
        tokens1[0] = address(CRV);
        tokens1[1] = address(WETH);
        
        uint256 crv_needed = UNIROUTER.getAmountsIn(getRewardGasWei, tokens1)[0];
        vals_[0].crvNeeded4Reward = crv_needed;

        uint256 rewardCRVTokenAmountForTreasury = rewardAmountForCRVToken * rewardTreasuryRate / TOTALRATE; // 30% of reward goes to treasur
        uint256 rewardCRVTokenAmountForUsers = rewardAmountForCRVToken - rewardCRVTokenAmountForTreasury;
        
        require(rewardCRVTokenAmountForUsers > crv_needed, "CRV reward from gauge not yet big enough for mass autocompound");
        rewardCRVTokenAmountForUsers = rewardCRVTokenAmountForUsers - crv_needed; // subtract out CRV needed for gasReward
        vals_[0].crv4LP = rewardCRVTokenAmountForUsers;
        
        if (rewardCRVTokenAmountForUsers > 0){
            assessGasV2(); 
        }

        uint256 rewardPylonTokenAmountForUsers = token1.balanceOf(address(this));
        
        // apportion respective amounts to be made into ETH-PYLON LP Token
        uint256 AmountForUsersCRV2PYLON = rewardCRVTokenAmountForUsers / 2; // 50% of the 70% will be converted to Pylon
        vals_[0].crv4pylonLP = AmountForUsersCRV2PYLON;
        uint256 amountForUsersCRV2WETH = rewardCRVTokenAmountForUsers / 2; // other 50% of the 70% will be converted to WET
        vals_[0].crv4wethLP = amountForUsersCRV2WETH;
        
        
        // combine the 50% CRV for user and 30% CRV for treasury so that only one call is made to convert CRV to WETH, will apportion returned WETH correctly below
        uint256 totalCrv2WethReward = amountForUsersCRV2WETH + rewardCRVTokenAmountForTreasury; 

        if (rewardCRVTokenAmountForUsers > 0) {
            UNIROUTER.swapExactTokensForTokens(AmountForUsersCRV2PYLON, 0, tokens, address(this), type(uint).max);
        }

        uint256 wethBalance = WETH.balanceOf(address(this));
        if (totalCrv2WethReward > 0) {
            UNIROUTER.swapExactTokensForTokens(totalCrv2WethReward, 0, tokens1, address(this), type(uint).max);
        }

        wethBalance = WETH.balanceOf(address(this)) - wethBalance;

        // lpWETH gets set to the proportion of WETH to go to users (that will be used in LP token creation)
        uint256 lpWETH = wethBalance * TOTALUSERWETHSHARE / TOTALWETHRATE; // rougly 54% of WETH returned from CRV 2 WETH swap will go to LP token creation
        vals_[0].wethUser = lpWETH;
        uint256 treasuryWETH = wethBalance - lpWETH; // remaining ~46% of CRV 2 WETH swap goes to treasury

        // Pylon amount to be combined with WETH to make LP Token
        vals_[0].pylonAmount = token1.balanceOf(address(this)) - rewardPylonTokenAmountForUsers;

        addLiquidityAndStakeI(); // make LP token

        // Transfer reward to Treasury
        if (treasuryWETH > 0) {
            WETH.transfer(treasury, treasuryWETH);
        }
    }

    function addLiquidityAndStakeI() internal {
        
        uint pylonSent;
        uint wethSent;
        uint lpTotalReward;

        // approving again; will test removing these as constructor should be doing this...
        WETH.approve(address(LPT), type(uint).max);
        token1.approve(address(LPT), type(uint).max);
        
        finalP = vals_[0].pylonAmount;
        finalW = vals_[0].wethUser;
        
        // Need 50/50 PYLON/WETH for LP Token
        if (finalP > finalW){
            finalP = finalW;
        }
        if (finalW > finalP){
            finalW = finalP;
        }

        // makes PYLON-ETH LP Token and sends to contract
        (pylonSent, wethSent, lpTotalReward) = UNIROUTER.addLiquidity(address(token1), address(WETH), finalP, finalW, 0,  0, address(this), block.timestamp); 

        global_[0].lpTokenReward = LPT.balanceOf(address(this));
    }

    function _depositYCRV(uint amount) internal updateBalance(msg.sender) {

        uint feeAmount = amount * feeRate / TOTALRATE;
        uint realAmount = amount - feeAmount;

        if (feeAmount > 0) {
            token0.transferFrom(msg.sender, feeAddress, feeAmount);
        }
        
        if (realAmount > 0) {
            token0.transferFrom(msg.sender, address(this), realAmount);
            YCRVGAUGE.deposit(realAmount);
            user_[msg.sender].depositBalancePerUser += realAmount;
            global_[0].totalDeposit += realAmount;
            global_[0].totalDepositForAPY += realAmount;
            emit yCRVDeposited(msg.sender, realAmount);
        }
    }

    // need to reset accounts when switching on metamask and remix
    function depositYCRV(uint amount) external {
        require(amount > 0, "deposit must be greater than 0");
        // check if user has deposited before, if not then will add to stakeholder list, otherwise does nothing
        addStakeholder(msg.sender);
        global_[0].userCount = stakeholders.length; // update this before updateBalance modifier is applied to _deposit
        _depositYCRV(amount);
    }

    function updateUserPylonReward() internal {

        // grab total pylon reward from pvault
        pvault.claimRewardAll();
        uint256 PYLON = token1.balanceOf(address(this));
        global_[0].totalPYLON += PYLON;

        // loop through stakeholders array and update each user's pylon reward
        for (uint i=0; i < global_[0].userCount ; i += 1) {

            address ua = stakeholders[i];
            user_[ua].rewardedPYLON += PYLON * user_[ua].accDepositBalancePerUser / global_[0].accTotalDeposit;
        }
    }

    // same as withdrawAndClaimAllRewards except leaves the yCRV deposited in the gauge
    function ClaimAllRewards() external updateBalance(msg.sender) {
        
        // LPT Withdrawl from PVAULT
        uint lpDepositBalance = user_[msg.sender].lpTokenUserReward; 
        uint amountWithdrawForLPT = LPT.balanceOf(address(this));
        pvault.withdraw(lpDepositBalance); // assumes that this contract's address is sent to pvault so that the transfer below must happen
        amountWithdrawForLPT = LPT.balanceOf(address(this)) - amountWithdrawForLPT;
        LPT.transfer(msg.sender, amountWithdrawForLPT); // assumes that 

        user_[msg.sender].lpTokenUserReward = user_[msg.sender].lpTokenUserReward - amountWithdrawForLPT; // should be 0 after thi
        global_[0].lpTotalDeposit -= amountWithdrawForLPT;

        // PYLON Withdrawl from PVAULT
        updateUserPylonReward();
        uint256 amountWithdrawForPYLON = user_[msg.sender].rewardedPYLON; 
        global_[0].totalPYLON -= amountWithdrawForPYLON;

        token1.transfer(msg.sender, amountWithdrawForPYLON);

        emit AllRewardsClaimed(msg.sender, amountWithdrawForLPT, amountWithdrawForPYLON);
    }

    // need to test assumption that this contract's address is being used here rather than sending on msg.sender to the pvault contract; I think its the former
    function _withdrawAndClaimAllRewards() internal updateBalance(msg.sender) {
        
        uint ycrvDepositBalance = user_[msg.sender].depositBalancePerUser;
        uint amountWithdrawForYCRV = token0.balanceOf(address(this));
        YCRVGAUGE.withdraw(ycrvDepositBalance);
        amountWithdrawForYCRV = token0.balanceOf(address(this)) - amountWithdrawForYCRV;
        token0.transfer(msg.sender, amountWithdrawForYCRV);
        
        user_[msg.sender].depositBalancePerUser = ycrvDepositBalance - amountWithdrawForYCRV;
        global_[0].totalDeposit -= amountWithdrawForYCRV;

        // LPT Withdrawl from PVAULT
        uint lpDepositBalance = user_[msg.sender].lpTokenUserReward; 
        uint amountWithdrawForLPT = LPT.balanceOf(address(this));
        pvault.withdraw(lpDepositBalance); // assumes that this contract's address is sent to pvault so that the transfer below must happen
        amountWithdrawForLPT = LPT.balanceOf(address(this)) - amountWithdrawForLPT;
        LPT.transfer(msg.sender, amountWithdrawForLPT); // assumes that 

        user_[msg.sender].lpTokenUserReward = user_[msg.sender].lpTokenUserReward - amountWithdrawForLPT; // should be 0 after thi
        global_[0].lpTotalDeposit -= amountWithdrawForLPT;

        // PYLON Withdrawl from PVAULT
        updateUserPylonReward();
        uint256 amountWithdrawForPYLON = user_[msg.sender].rewardedPYLON; 
        global_[0].totalPYLON -= amountWithdrawForPYLON;

        token1.transfer(msg.sender, amountWithdrawForPYLON);

        emit WithdrawnAndAllRewardsClaimed(msg.sender, amountWithdrawForYCRV, amountWithdrawForLPT, amountWithdrawForPYLON);
    }

    function withdrawAndClaimAllRewards() external {
        removeStakeholder(msg.sender);
        global_[0].userCount = stakeholders.length; //need to make sure that stakeholders array is actually getting updated properly
        _withdrawAndClaimAllRewards();
    }
    
    function autoCompoundCRV2PVAULT() external updateBalance(msg.sender) {
        getRewardI(); 

        require(global_[0].userCount > 0, "no users have deposited");
        uint256 LPTReward = global_[0].lpTokenReward;
        require(LPTReward > 0, "can't deposit 0 LP token into pvault");
        
        uint256 userLPTReward = LPTReward * user_[msg.sender].accDepositBalancePerUser / global_[0].accTotalDeposit; // adjust for User's share before depositing on their behalf
        user_[msg.sender].lpTokenUserReward = userLPTReward; // will need to decrement this in the PVWithdraw function

        // do pvault deposit here
        if (userLPTReward > LPTReward) {
            userLPTReward = LPTReward;
        }
        if (userLPTReward > 0) {
            
            LPT.approve(address(this), type(uint).max);
            LPT.approve(address(pvault), type(uint).max);

            pvault.deposit(userLPTReward);
            global_[0].lpTotalDeposit += userLPTReward; // keep track of total LP deposited by this contract

            emit AutoCompoundedCRV2PVAULT(msg.sender, userLPTReward);
        }      
    }

    // only using for testing for now
    function alterMassTS() external {
        global_[0].lastMassDrainTimestamp -= delayDuration;
    }

    function updateUserLPTReward() internal {

        uint256 LPTReward = global_[0].lpTokenReward;

        for (uint i=0; i < global_[0].userCount ; i += 1) {

            address ua = stakeholders[i];
            uint256 userLPTReward = LPTReward * user_[ua].accDepositBalancePerUser / global_[0].accTotalDeposit;
            user_[ua].lpTokenUserReward  += userLPTReward;
        }
    }

    function massAutoCompoundCRV2PVAULT() external updateBalanceAllUsers() {
        
        isMassDrainEligible(); // check that 24 hours has passed since last call 
        require(global_[0].isEligibleI == true, "24 hours has not yet passed since last mass drain");
        require(global_[0].userCount > 1, "2 or more users need to have deposited - use claimReward instead");

        getRewardAll();  

        uint256 LPTReward = global_[0].lpTokenReward; 
        require(LPTReward > 0, "can't deposit 0 LP token into pvault");

        updateUserLPTReward(); // update all user's share of LP Token reward

        LPT.approve(address(this), type(uint).max); 
        LPT.approve(address(pvault), type(uint).max); 

        pvault.deposit(LPTReward); 

        global_[0].lpTotalDeposit += LPTReward; // keep track of total LP deposited by this contract
            
        global_[0].lastMassDrainTimestamp = block.timestamp;
        emit MassAutoCompoundedCRV2PVAULT(msg.sender, LPTReward);
    }

    function seize(address token, address to) external onlyGov {
        require(IERC20(token) != token1, "main tokens");
        if (token != address(0)) {
            uint amount = IERC20(token).balanceOf(address(this));
            IERC20(token).transfer(to, amount);
        }
        else {
            uint amount = address(this).balance;
            payable(to).transfer(amount);
        }
    }
        
    fallback () external payable { }
    receive () external payable {}
}