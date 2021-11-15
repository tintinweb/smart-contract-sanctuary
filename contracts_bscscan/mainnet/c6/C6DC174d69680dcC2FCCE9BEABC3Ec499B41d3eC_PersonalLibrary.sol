// SPDX-License-Identifier: GPLv2
//TODO: upgrade to solidity 8
pragma solidity ^0.5.17;
pragma experimental ABIEncoderV2;
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20Burnable.sol";

interface IYZapIn {
    function YZapIn(
        address _toWhomToIssue,
        address _fromTokenAddress,
        address _toPairAddress,
        uint256 _amount,
        uint256 _minPoolTokens
    ) external payable returns (uint256);


    function YZapInAndStake(
        address fromTokenAddress,
        address stakeContractAddress,
        uint256 amount,
        uint256 minStakeTokens
    ) external payable returns (uint256);
}

interface YZap {
    function routerAddress() external returns (address);
}

interface ITokenExchangeRouter {
    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);
    
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint amountOutMin, 
        address[] calldata path, 
        address to, 
        uint deadline
    ) external payable returns (uint[] memory amounts);
}

interface IYZapOut {
    function YZapOut(
        address _toWhomToIssue,
        address _toTokenAddress,
        address _fromPoolAddress,
        uint256 _amount,
        uint256 _minToTokens
    ) external payable returns (uint256);

    //for curve only
    function getTokenAddressFromSwapAddress(
        address _fromPairAddress
    ) external view returns (address);
}

//note: this is combined set of function, check if pool indeed contains required function
interface IStakeOrDepositPool {
    function stake(uint256 amount) external;
    function deposit(uint256 amount) external;
    function deposit(address lptoken, uint256 amount) external;
    function poolAddresses(uint256 index) external returns(address);
    function withdraw(uint256 amount) external;
    function withdraw(address lptoken, uint256 amount) external;
    function getReward() external;
    function exit() external;
}

interface IStakeOrDepositPoolWithPID {
    function deposit(uint256 pid, uint256 amount) external;
    function deposit(uint256 pid, uint256 amount, bool state) external;
    function deposit(uint256 pid, uint256 amount, address refferer) external;
    function deposit(uint256 pid, uint256 amount, address refferer, bool state) external;
    function deposit(address user, uint256 pid, uint256 amount) external;
    function withdraw(uint256 pid, uint256 amount) external;
    function withdraw(uint256 pid, uint256 amount, bool state) external;
    function withdraw(address user, uint256 pid, uint256 amount) external;
}

interface IStakeWithBytes {
    function stake(uint256 amount, bytes calldata b) external;
    function unstake(uint256 amount, bytes calldata b) external;
}

interface IDepositWithRidPool {
    function depositToken(uint256 _rid, uint256 _amount) external;
    function withdrawToken(uint256 _rid, uint256 _amount) external;
}

interface IDepositWithCashout {
    function deposit(uint256 amount) external;
    function cashout(uint256 amount) external;
}

interface IMarketPool {
    function mint(uint256 amount) external;
    function claimVenus(address user) external;
}

interface IYIELDPool {
    function stakeAndAssignTo(address assignTo, uint256 amount) external;
    function withdraw(uint256 amount) external;
    function getReward() external;
    function exit() external;
}

interface IVaultProxy {
    function deposit(uint256 amount) external;
    function withdraw(uint256 amount) external;
    function userInfo(address user) external returns(uint256, uint256);
    function pendingRewards() external returns(uint256);
    function mint(uint256 amount) external;
}


interface IFactory {
    function directCallAddresses(address _address) external returns (bool);
    function getContractToConvertTokens() external returns (address);
    function getInContract(uint256 _exchange) external returns (address);
    function getOutContract(uint256 _exchange) external returns (address);
    function isAddressApprovedForStaticFunctions(address _address, uint256 riskLevel) external view returns (bool);
    function isAddressApprovedForDirectCallFunction(address _address, uint256 riskLevel) external view returns (bool);
    function yieldStakeContract() external view returns (address);
    function yieldStakePair() external view returns (address);
    function yieldStakeExchange() external view returns (uint256);
    function developmentFund() external view returns (address payable);
    function onRewardNativeDevelopmentFund() external view returns (uint256);//5.00%
    function onRewardNativeBurn() external view returns (uint256);//5.00%
    function onRewardYieldDevelopmentFund() external view returns (uint256);//2.50%
    function onRewardYieldBurn() external view returns (uint256);//2.50%
    function generatePersonalContractEvent(string calldata _type, bytes calldata _data) external;
}

interface IWBNBWETH {
    function deposit() external payable;
    function withdraw(uint256 wad) external;
}

/**
@notice Personal contract, used by Factory contract. 
@notice Contains all functions needed for investments
@notice Contains all functions needed for investments
@notice variable investor is owner of deposit funds
@notice variable strategist is address used to run investment commands
@notice variable factory address of factory contract
@notice variable pairInvestmentHistory get log history [by address]
@notice variable Investments get log history [by index]
*/
contract PersonalLibrary {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    //index matters, don't change order
    enum Strategy { 
        STAKE,
        DEPOSIT, 
        DEPOSIT_WITH_PID, 
        STAKE_WITH_PID, 
        DEPOSIT_WITH_TOKEN, 
        DEPOSIT_WITH_PID_AND_BOOL, 
        DEPOSIT_WITH_PID_AND_REFERRER,
        DEPOSIT_AND_WITHDRAW,
        DIRECT_CALL,
        MINT_AND_CLAIM,
        DEPOSIT_WITH_PID_FOR,
        DEPOSIT_WITH_PID_REFERRER_AND_BOOL,
        STAKE_WITH_BYTES,
        DEPOSIT_WITH_RID,
        DEPOSIT_WITH_CASHOUT
    } //last index: 14

    uint256 public version = 1;
    address payable public investor;
    address public strategist;
    address public factory;
    //address public personalLib;
    address yieldToken;
    address networkNativeToken;//WETH or WBNB
    mapping (address => uint256) public pairInvestmentHistory;
    mapping (uint256 => address[]) public Investments;
    event ValueReceived(address user, uint amount, address token);
    uint256 constant percentageDecimals = 10000;//two => 100.00%
    uint256 public riskLevel;

    bool private _notEntered;

    event RewardStaked(uint256 lpAmount, address[] tokens);
    event RewardNativeClaimed(uint256 yieldBurn, uint256 ethToDevelopment, uint256 amountToInvestor);
    event RewardYieldClaimed(uint256 yieldBurn, uint256 amountToConvertToETH, uint256 amountToInvestor);
    event LiquidityUnstakedAndWithdrawn(address stakePool);
    event stopLossCalled(uint256 unstaked, uint256 rewardConverted);


    struct ProvideLiquiditySet {
        uint256 exchange;
        address tokenAddress;
        address pairAddress;
        address liquidityPoolOutputTokenAddress;
        uint256 amount;
        uint256 minPoolTokens;
    }

    struct LiquidityToVaultSet {
        Strategy poolTemplate;
        address vaultAddresses;
        uint256 pid;//BACKEND-FRONTEND: new parameter  pid
        //TODO: add the pid in new contract; search key: #iOcby3 and liquidityToVault
    }

    struct StakeSet {
        Strategy poolTemplate; 
        address stakeContractAddress; 
        address tokenToStake;
        uint256 pid;
        bytes extraBytes;//BACKEND-FRONTEND: new parameter  extraBytes
    }
    
    struct UnstakeSet {
        Strategy poolTemplate;
        address stakeContractAddress; 
        uint256 amount;
        uint256 pid;
        bytes extraBytes;//BACKEND-FRONTEND: new parameter  extraBytes
    }

    struct VaultToLiquiditySet {
        address vaultAddress;
    }

    struct WithdrawLiquiditySet {
        uint256 exchange;
        address toWhomToIssue;
        address toTokenAddress;
        address fromTokenAddress;
        address fromliquidityPoolAddress;
        uint256 minTokensRec;
    }
    
    /**
     * @dev Throws if called by any account other than the strategist.
     */
    modifier onlyStrategist() {
        require(msg.sender == strategist, "!strategist");
        _;
    }

    modifier strategistOrInvestor() {
        require(msg.sender == strategist || msg.sender == investor, "!strategist!investor");
        _;
    }

    /**
     * @dev Throws if called by any account other than the investor.
     */
    modifier onlyInvestor() {
        require(msg.sender == investor, '!investor');
        _;
    }

    /**
     * @dev simple custom ReentrancyGuard solution cause
     * failed to run ReentrancyGuard from openzeppelin with initialize/ProxyFactory 
     * (due to private _notEntered and constructor)
     */
    modifier nonReentrant() {
        require(_notEntered, 'already entered');
        _notEntered = false;
        _;
        _notEntered = true;
    }
    
    /**
    @notice This function is called only once for every new personal contract
    @param _investor can deposit and withdraw funds
    @param _strategist can invest available funds
    @param _riskLevel max risk level for this contract (0-100%)
    @param _networkNativeToken address of WETH or WBNB
    @param _yieldToken address of Yield Protocol token
    */
    function initialize (
        address payable _investor, 
        address _strategist, 
        uint256 _riskLevel,
        address _networkNativeToken,
        address _yieldToken
    ) public {
        require(factory == address(0), 'contract is already initialized');
        factory = msg.sender;
        investor = _investor;
        strategist = _strategist;
        riskLevel = _riskLevel;
        networkNativeToken = _networkNativeToken;
        yieldToken = _yieldToken;
        _notEntered = true;//cause no pre defined variables on ProxyFactory
    }
    
    /**
    @notice This function is used to invest in given LP pair through ETH/ERC20 Tokens
    @param _exchange is liquidity pool index taken from Factory contract
    @param _ToWhomToIssue is address of personal contract for this user
    @param _fromTokenAddress The ERC20 token used for investment (address(0x00..) if ether)
    @param _toPairAddress The liquidity pool pair address
    @param _amount The amount of fromToken to invest
    @param _minPoolTokens Reverts if less tokens received than this
    @return Amount of LP bought
    */
    function provideLiquidity(
        uint256 _exchange, 
        address _ToWhomToIssue,
        address _fromTokenAddress, 
        address _toPairAddress, 
        uint256 _amount, 
        uint256 _minPoolTokens
    ) public strategistOrInvestor returns (uint256) {
        require(_ToWhomToIssue == address(this) || _ToWhomToIssue == investor, '!allowed');
        logNewPair(_exchange, _toPairAddress);

        address inContract = IFactory(factory).getInContract(_exchange);
        uint256 ethValue;

        if(_fromTokenAddress == address(0)){
            ethValue = _amount;
        }else{
            _approve(_fromTokenAddress, inContract, _amount);
        }

        return IYZapIn(inContract).YZapIn.value(ethValue)(
            _ToWhomToIssue,
            _fromTokenAddress,
            _toPairAddress,
            _amount,
            _minPoolTokens
        );
    }

    /**
    @notice This function is used to withdraw liquidity from pool
    @param _exchange is liquidity pool index taken from Factory contract
    @param _ToWhomToIssue is address of personal contract for this user
    @param _ToTokenContractAddress The ERC20 token to withdraw in (address(0x00) if ether)
    @param _fromPairAddress The pair address to withdraw from
    @param _amount The amount of liquidity pool tokens (LP)
    @param _minTokensRec Reverts if less tokens received than this
    @return the amount of eth/tokens received after withdraw
    */
    function withdrawLiquidity(
        uint256 _exchange,
        address _ToWhomToIssue,
        address _ToTokenContractAddress,
        address _fromPairAddress,
        uint256 _amount,
        uint256 _minTokensRec
    ) public payable strategistOrInvestor nonReentrant returns (uint256){
        require(_ToWhomToIssue == address(this) || _ToWhomToIssue == investor, '!allowed');

        uint256 tokenBought = YZapOut(
            _ToWhomToIssue,
            _exchange,
            _ToTokenContractAddress,
            _fromPairAddress,
            _amount,
            _minTokensRec
        );
        return tokenBought;
    }


    
    /**
    @notice the function stakes token into provided pool.
    @notice pool's "stake" function must match one of hardcoded template
    @param _poolTemplate template of the pool. 0 = STAKE, 1 = DEPOSIT and so on..
    @param _stakeContractAddress The stake contract address
    @param _tokenToStake is address of a token or lp/flp pair to be staked
    @param _amount The amount of _fromTokenAddress to invest
    @param _pid id of the pool in masterchef contract..
    @param extraBytes set of bytes for any extra data
    */
    function stake(
            Strategy _poolTemplate, 
            address _stakeContractAddress, 
            address _tokenToStake, 
            uint256 _amount, 
            uint256 _pid, 
            bytes memory extraBytes
        ) onlyStrategist public {
        
        //BACKEND-FRONTEND: new parameter  bytes memory extraBytes

        require(IFactory(factory).isAddressApprovedForStaticFunctions(_stakeContractAddress, riskLevel), 'address is not approved');

        if(_stakeContractAddress != address(0)) {
            _approve(_tokenToStake, _stakeContractAddress, _amount);
        }

        if(_poolTemplate == Strategy.STAKE){
            IStakeOrDepositPool(_stakeContractAddress).stake(_amount);
        }else if(_poolTemplate == Strategy.DEPOSIT || _poolTemplate == Strategy.DEPOSIT_AND_WITHDRAW){
            IStakeOrDepositPool(_stakeContractAddress).deposit(_amount);
        }else if(_poolTemplate == Strategy.DEPOSIT_WITH_PID){
            IStakeOrDepositPoolWithPID(_stakeContractAddress).deposit(_pid, _amount);
        } else if(_poolTemplate == Strategy.DEPOSIT_WITH_TOKEN){
            address tokenAddress = abi.decode(extraBytes, (address));
            IStakeOrDepositPool(_stakeContractAddress).deposit(tokenAddress, _amount);
        } else if(_poolTemplate == Strategy.DEPOSIT_WITH_PID_AND_BOOL) {
            IStakeOrDepositPoolWithPID(_stakeContractAddress).deposit(_pid, _amount, false);
        } else if(_poolTemplate == Strategy.DEPOSIT_WITH_PID_AND_REFERRER) {
            IStakeOrDepositPoolWithPID(_stakeContractAddress).deposit(_pid, _amount, address(0));
        } else if(_poolTemplate == Strategy.DIRECT_CALL){
            directCall(_stakeContractAddress, extraBytes, address(0), bytes(""));
        } else if(_poolTemplate == Strategy.MINT_AND_CLAIM) {
            IMarketPool(_stakeContractAddress).mint(_amount);
        } else if(_poolTemplate == Strategy.DEPOSIT_WITH_PID_FOR) {
            IStakeOrDepositPoolWithPID(_stakeContractAddress).deposit(address(this), _pid, _amount);
        } else if(_poolTemplate == Strategy.DEPOSIT_WITH_PID_REFERRER_AND_BOOL) {
            // false means (in koaladeFi) we will pay fee by lp tokens
            IStakeOrDepositPoolWithPID(_stakeContractAddress).deposit(_pid, _amount, address(0), false);
        } else if(_poolTemplate == Strategy.STAKE_WITH_BYTES) {
            IStakeWithBytes(_stakeContractAddress).stake(_amount, bytes('0'));
        } else if(_poolTemplate == Strategy.DEPOSIT_WITH_RID) {
            IDepositWithRidPool(_stakeContractAddress).depositToken(_pid, _amount);
        } else if(_poolTemplate == Strategy.DEPOSIT_WITH_CASHOUT) {
            IDepositWithCashout(_stakeContractAddress).deposit(_amount);
        }

        //no need to check this, since we will get revert on function call if provided pool is wrong 
        //revert('stake: wrong pool template');
    }

    /**
    @notice This function is used to unstake tokens
    @param _poolTemplate template of the pool. 0 = STAKE, 1 = DEPOSIT and so on..
    @param _stakeContractAddress The stake contract address
    @param _amount The amount of tokens to withdraw
    @param _pid id of the pool in masterchef contract..
    @param extraBytes set of bytes for any extra data
    */
    function unstake(
        Strategy _poolTemplate,
        address _stakeContractAddress,
        uint256 _amount,
        uint256 _pid,
        bytes memory extraBytes
    ) public strategistOrInvestor {

        //BACKEND-FRONTEND: new parameter  bytes memory extraBytes
        if(_poolTemplate == Strategy.DEPOSIT_WITH_PID 
        || _poolTemplate == Strategy.DEPOSIT_WITH_PID_AND_REFERRER 
        || _poolTemplate == Strategy.DEPOSIT_WITH_PID_REFERRER_AND_BOOL){
            IStakeOrDepositPoolWithPID(_stakeContractAddress).withdraw(_pid, _amount);
            //getReward called automatically
        } else if(_poolTemplate == Strategy.DEPOSIT_WITH_TOKEN) {
            address tokenAddress = abi.decode(extraBytes, (address));
            IStakeOrDepositPool(_stakeContractAddress).withdraw(tokenAddress, _amount);
            //getReward called automatically
        } else if(_poolTemplate == Strategy.DEPOSIT_WITH_PID_AND_BOOL){
            IStakeOrDepositPoolWithPID(_stakeContractAddress).withdraw(_pid, _amount, true);
            //getReward called automatically
        } else if(_poolTemplate == Strategy.DIRECT_CALL){
            directCall(_stakeContractAddress, extraBytes, address(0), bytes(""));
        } else if(_poolTemplate == Strategy.MINT_AND_CLAIM) {
            IMarketPool(_stakeContractAddress).claimVenus(address(this));
        } else if(_poolTemplate == Strategy.DEPOSIT_WITH_PID_FOR) {
            IStakeOrDepositPoolWithPID(_stakeContractAddress).withdraw(address(this), _pid, _amount);
        } else if(_poolTemplate == Strategy.STAKE_WITH_BYTES) {
            IStakeWithBytes(_stakeContractAddress).unstake(_amount, bytes('0'));
        } else if(_poolTemplate == Strategy.DEPOSIT_WITH_RID) {
            IDepositWithRidPool(_stakeContractAddress).withdrawToken(_pid, _amount);
        } else if(_poolTemplate == Strategy.DEPOSIT_WITH_CASHOUT) {
            IDepositWithCashout(_stakeContractAddress).cashout(_amount);
        } else {
            IStakeOrDepositPool(_stakeContractAddress).withdraw(_amount);
            if(_poolTemplate != Strategy.DEPOSIT_AND_WITHDRAW) {
                IStakeOrDepositPool(_stakeContractAddress).getReward();
            }
        }
    }
    
    /**
    @notice This function is used to farm tokens, example: 3Crv -> f3Crv
    @notice Didn't include Strategy.DEPOSIT_WITH_PID, cause no vault found with such deposit
    @param _poolTemplate template of the pool. 0 = STAKE, 1 = DEPOSIT.
    @param _vaultAddresses address of the Vault where to deposit lp
    @param _fromPairAddress is a sours of lp tokens
    @param _amount amount of lp tokens to farm
    @param _pid id of the pool in masterchef contract..
    */
    function liquidityToVault(
        Strategy _poolTemplate, 
        address _vaultAddresses, 
        address _fromPairAddress, 
        uint256 _amount,
        uint256 _pid
    ) public onlyStrategist {
        //BACKEND-FRONTEND: new parameter  _pid
        //TODO: think about staking directly
       stake(_poolTemplate, _vaultAddresses, _fromPairAddress, _amount, _pid, bytes(""));
    }

    /**
    @notice This function is used to unfarm flp tokens, example: f3Crv -> 3Crv
    @notice Didn't add _poolTemplate, cause all known use same withdraw function
    @param vaultAddress source of farmed tokens
    */
    function vaultToLiquidity(address vaultAddress) public strategistOrInvestor {
        IVaultProxy(vaultAddress).withdraw(IERC20(vaultAddress).balanceOf(address(this)));
    }


    /********* Wrapper section *******/

    
    /**
    @notice This function is used to exchange liquidity pool tokens in one transaction
    @param _fromExchange is liquidity pool index taken from Factory contract
    @param _fromPairAddress source pair address of lp tokens
    @param _toExchange is liquidity pool index taken from Factory contract
    @param _toPairAddress new pair address of lp tokens
    @param _amount The amount of liquidity pool tokens (LP)
    @param _minPoolTokens Reverts if less tokens received than this
    @return Amount of LP bought
    */
    function swapLiquidity(
        uint256 _fromExchange,
        address _fromPairAddress,
        uint256 _toExchange,
        address _toPairAddress,
        uint256 _amount,
        uint256 _minPoolTokens
    ) public onlyStrategist returns (uint256) {

        logNewPair(_toExchange, _toPairAddress);

        uint256 intermediateAmount = YZapOut(
            address(this),
            _fromExchange,
            networkNativeToken,
            _fromPairAddress,
            _amount,
            1
        );

        return provideLiquidity(
            _toExchange,
            address(this),
            networkNativeToken,
            _toPairAddress,
            intermediateAmount,
            _minPoolTokens
        );
    
    }

    
    /**
    @notice This function is used to provide liquidity and stake with one transaction [harvest]
    @param _pl is a struct of variables that will be used in provideLiquidity function
    @param _lv ... liquidityToVault function
    @param _st ... stake function
    */
    function provideLiquidityAndStake(
        ProvideLiquiditySet memory _pl,
        LiquidityToVaultSet memory _lv,
        StakeSet memory _st
    ) public onlyStrategist {
        uint256 balance = _pl.amount;

            if(_pl.exchange > 0){
                balance = provideLiquidity(_pl.exchange, address(this), _pl.tokenAddress, _pl.pairAddress, _pl.amount, _pl.minPoolTokens);
            }else if(_pl.tokenAddress != _pl.pairAddress){
                balance = _pl.tokenAddress != address(0) 
                ? convertTokenToToken(address(this), _pl.tokenAddress, _pl.pairAddress, _pl.amount)
                : convertETHToToken(address(this), _pl.pairAddress, _pl.amount);
            }
   
            if(_lv.vaultAddresses != address(0)){
                //TODO: add the pid in new contract; search key: #iOcby3 and liquidityToVault
                liquidityToVault(_lv.poolTemplate, _lv.vaultAddresses, _pl.liquidityPoolOutputTokenAddress, balance, _lv.pid);
                balance = IERC20(_st.tokenToStake).balanceOf(address(this));
            }

            if(_st.stakeContractAddress != address(0) && _st.poolTemplate != Strategy.MINT_AND_CLAIM){
                stake(_st.poolTemplate, _st.stakeContractAddress, _st.tokenToStake, balance, _st.pid, _st.extraBytes);
            }
    }

    /**
    @notice This function is used to unstake and withdraw liquidity with one transaction [harvest]
    @param _un is a struct of variables that will be used in unstake function
    @param _vl ... vaultToLiquidity function
    @param _wl ... withdrawLiquidity function
    */
    function unstakeAndWithdrawLiquidity(
        UnstakeSet memory _un,
        VaultToLiquiditySet memory _vl,
        WithdrawLiquiditySet memory _wl
    ) public strategistOrInvestor {

        if(_un.stakeContractAddress != address(0)){
            unstake(_un.poolTemplate, _un.stakeContractAddress, _un.amount, _un.pid, _un.extraBytes);
        }

        if(_vl.vaultAddress != address(0) && _un.poolTemplate != Strategy.MINT_AND_CLAIM){
            vaultToLiquidity(_vl.vaultAddress);
        }

        if(_wl.exchange > 0){
            withdrawLiquidity(
                _wl.exchange, 
                _wl.toWhomToIssue,
                _wl.toTokenAddress, 
                _wl.fromTokenAddress, 
                IERC20(_wl.fromliquidityPoolAddress).balanceOf(address(this)), 
                _wl.minTokensRec
            );
        }else if(_wl.toTokenAddress != _wl.fromTokenAddress){
            uint256 _balance = IERC20(_wl.fromTokenAddress).balanceOf(address(this));
            if(_balance > 0) {
                if(_wl.toTokenAddress != address(0)){
                    convertTokenToToken(_wl.toWhomToIssue, _wl.fromTokenAddress, _wl.toTokenAddress, _balance);
                }else{
                    convertTokenToETH(_wl.toWhomToIssue, _wl.fromTokenAddress, _balance);
                }
            }
        }

        emit LiquidityUnstakedAndWithdrawn(_un.stakeContractAddress);
        IFactory(factory).generatePersonalContractEvent("LiquidityUnstakedAndWithdrawn", bytes(""));
    }

    /**
    @notice simple wrapper to claim & exit in one transaction
    @param _rewardType reward function selector
    */
    function unstakeAndWithdrawLiquidityAndClaimReward(
        UnstakeSet memory _un,
        VaultToLiquiditySet memory _vl,
        WithdrawLiquiditySet memory _wl,
        uint256 _rewardType,
        address[] memory _tokens, 
        address[] memory _pools
    ) public strategistOrInvestor {
        unstakeAndWithdrawLiquidity(_un, _vl, _wl);

        if(_rewardType == 1){
            claimRewardNativeTokens(_tokens,  _pools);
        }else if(_rewardType == 2){
            claimRewardYIELDTokens(_tokens,  _pools);
        }else if(_rewardType == 3){
            stakeReward(_tokens, _pools);
        }
    }

    /**
    @notice simple wrapper to claim & exit in one transaction
    */
    function stopLossExit(
        UnstakeSet memory _un,
        VaultToLiquiditySet memory _vl,
        WithdrawLiquiditySet memory _wl,
        address[] memory _tokens
    ) public onlyStrategist {
        uint256 initialBalance = investor.balance;
        uint256 rewardConverted;
        uint256 unstaked;

        unstakeAndWithdrawLiquidity(_un, _vl, _wl);

        unstaked = investor.balance - initialBalance;
        if(_tokens.length > 0){
            claimRewardInNetworkNative(_tokens);
            rewardConverted = investor.balance - initialBalance - unstaked;
        }

        emit stopLossCalled(unstaked, rewardConverted);
    }

    /**
    @notice This function is used to combine several transactions into one action: restake
    @param _un is a struct of variables that will be used in unstake function
    @param _vl ... vaultToLiquidity function
    @param _wl ... withdrawLiquidity function
    @param _pl ... provideLiquidity function
    @param _lv ... liquidityToVault function
    @param _st ... stake function
    */
    function restake(
        UnstakeSet memory _un,
        VaultToLiquiditySet memory _vl,
        WithdrawLiquiditySet memory _wl,
        ProvideLiquiditySet memory _pl,
        LiquidityToVaultSet memory _lv,
        StakeSet memory _st
    ) public {

        //additional info:
        //_wl.toWhomToIssue - no need, always this contract
        //_wl_minTokensRec - doesn't metter, we have _pl.minPoolTokens
        //_wl.toTokenAddress - should be networkNativeToken or liquidityPoolOutputTokenAddress
        //_pl.tokenAddress == _wl.toTokenAddress
        //_pl.amount - we need to calculate this

        _wl.toWhomToIssue = address(this);
        if(_pl.exchange == 0){
             //no lp pair try to withdraw directly in required token
            _wl.toTokenAddress = _pl.liquidityPoolOutputTokenAddress;
        }else{
            //have to work with lp pairs
            //TODO: try to add direct swap
            _wl.toTokenAddress = networkNativeToken;
        }
        
        unstakeAndWithdrawLiquidity(
            _un, 
            _vl, 
            _wl
        );

        _pl.amount = IERC20(_wl.toTokenAddress).balanceOf(address(this));
        _pl.tokenAddress = _wl.toTokenAddress;

        provideLiquidityAndStake(
            _pl,
            _lv, 
            _st
        );
    }

    /**
    @notice 10% FEE - Claim your rewards in the native token you earned. 
    @notice 5% of those will go towards Buying and BURNING YIELD tokens, 
    @notice the other 5% will go to YFarmer to fund its future development
    @param _tokens array of reward token addresses to claim
    @param _pools array of staked pools. Helpful if it is needed to get 
    */
    function claimRewardNativeTokens(address[] memory _tokens, address[] memory _pools) strategistOrInvestor public {

        for (uint256 i; i < _pools.length; i++){
            IStakeOrDepositPool(_pools[i]).getReward();
        }

        uint256 rewardAmount;
        uint256 yieldBurn;
        uint256 ethToDevelopment;
        uint256 amountToInvestor;
        for (uint256 i; i < _tokens.length; i++){

            rewardAmount = IERC20(_tokens[i]).balanceOf(address(this));
            if(rewardAmount == 0) continue;

            yieldBurn = rewardAmount.sub(rewardAmount.mul(percentageDecimals.sub(IFactory(factory).onRewardNativeBurn())).div(percentageDecimals));
            ethToDevelopment = rewardAmount.sub(rewardAmount.mul(percentageDecimals.sub(IFactory(factory).onRewardNativeDevelopmentFund())).div(percentageDecimals));
            amountToInvestor = rewardAmount.sub(yieldBurn).sub(ethToDevelopment);

            IERC20(_tokens[i]).safeTransfer(
                investor,
                amountToInvestor
            );

            ethToDevelopment = convertTokenToETH(IFactory(factory).developmentFund(), _tokens[i], ethToDevelopment);
            
            //yieldBurn = convertTokenToYIELD(address(this), _tokens[i], yieldBurn);
            yieldBurn = convertTokenToToken(address(this), _tokens[i], yieldToken, yieldBurn);
            ERC20Burnable(yieldToken).burn(yieldBurn);

            emit RewardNativeClaimed(yieldBurn, ethToDevelopment, amountToInvestor);
            IFactory(factory).generatePersonalContractEvent("RewardNativeClaimed", bytes(""));
        }
        
    }


    /**
    @notice 5% FEE - Claim your rewards in YIELD tokens - 
    @notice 97.5% of your reward tokens will be used to market-buy YIELD,
    @notice and 2.5% of those will be burnt
    @param _tokens array of reward token addresses to claim
    @return amount of burned tokens, amount of tokens transferred to investor
    */
    function claimRewardYIELDTokens(address[] memory _tokens, address[] memory _pools) strategistOrInvestor public returns (uint256, uint256) {

        for (uint256 i; i < _pools.length; i++){
            IStakeOrDepositPool(_pools[i]).getReward();
        }

        //note: we don't expect small amounts of tokens here
        uint256 rewardAmount = convertRewardTokensToYIELD(address(this), _tokens);

        uint256 yieldBurn = rewardAmount.sub(rewardAmount.mul(percentageDecimals.sub(IFactory(factory).onRewardYieldBurn())).div(percentageDecimals));
        uint256 amountToConvertToETH = rewardAmount.sub(rewardAmount.mul(percentageDecimals.sub(IFactory(factory).onRewardYieldDevelopmentFund())).div(percentageDecimals));
        uint256 amountToInvestor = rewardAmount.sub(yieldBurn).sub(amountToConvertToETH);
        
        amountToConvertToETH = convertTokenToETH(IFactory(factory).developmentFund(), yieldToken, amountToConvertToETH);

        IERC20(yieldToken).safeTransfer(investor, amountToInvestor);
        ERC20Burnable(yieldToken).burn(yieldBurn);

        emit RewardYieldClaimed(yieldBurn, amountToConvertToETH, amountToInvestor);
        IFactory(factory).generatePersonalContractEvent("RewardYieldClaimed", bytes(""));

        return (yieldBurn, amountToInvestor);
        
    }


    /**
    @notice this is for stop loss, no fee
    @param _tokens array of reward token addresses to claim
    */
    function claimRewardInNetworkNative(address[] memory _tokens) onlyStrategist nonReentrant public {

        for (uint256 i; i < _tokens.length; i++){
            convertTokenToETH(investor, _tokens[i], IERC20(_tokens[i]).balanceOf(address(this)));
        }

        IFactory(factory).generatePersonalContractEvent("claimRewardInNetworkNative", bytes(""));
  
        
    }

    /**
    @notice set new stop loss level for this personal contract, 
    @notice please don't set this  
    @param _riskLevel is new risk level value (0 - 100 value, no decimals)
    */
    function setRiskLevel(uint256 _riskLevel) onlyInvestor external {
        riskLevel = _riskLevel;
    }

    /**
    @notice 0% FEE - Claim your rewards int LP tokens - 50% of the reward tokens will be used to buy YIELD, 
    @notice 50% will be used to buy ETH - and automatically added to the YIELD/ETH pool -
    @notice which will earn you more YIELD in staking rewards.
    @param _tokens array of reward token addresses to claim
    @return Amount of LP bought
    */
    function stakeReward(address[] memory _tokens, address[] memory _pools) strategistOrInvestor public returns (uint256) {

        for (uint256 i; i < _pools.length; i++){
            IStakeOrDepositPool(_pools[i]).getReward();
        }

        uint256 amountOfTokens = convertRewardTokensToYIELD(address(this), _tokens);
        //require(yieldTokenTokens > 0, 'yieldTokenTokens is empty');

        address stakePair = IFactory(factory).yieldStakePair();        
        uint256 providedLiquidity = provideLiquidity(
            IFactory(factory).yieldStakeExchange(), 
            investor,
            yieldToken, 
            stakePair, 
            amountOfTokens, 
            1
        );

        //TODO: uncomment this when pool deployed
        //TODO: change investor to address(this) in provideLiquidity function
        /*address stakeContract = IFactory(factory).yieldStakeContract();
        IERC20(stakePair).approve(
            stakeContract,
            providedLiquidity
        );*/

        //IStakeOrDepositPool(stakeContract).stake(providedLiquidity);
        //IyieldTokenPool(stakeContract).stakeAndAssignTo(investor, providedLiquidity);

        emit RewardStaked(providedLiquidity, _tokens);
        IFactory(factory).generatePersonalContractEvent("RewardStaked", bytes(""));

        return providedLiquidity;
    }

    /**
    @notice helper, allows to call any method with any data on the provided address.
    @notice safety is guaranteed by approved pools: we can not call this method on any address; 
    @notice so, fund of the investor still safe
    @notice positive moment of this func is that we can adopt almost instantly to investment flow change.
    @param _address1 address on which we should run provided bytecode
    @param _inuptBytes1 bytecode to call on address 1
    @param _address2 another address, just to do two transactions in one
    @param _inuptBytes2 another bytecode, just to do two transactions in one
    @return result of 1 call, result of 2 call 
    */
    function directCall(address _address1, bytes memory _inuptBytes1, address _address2, bytes memory _inuptBytes2) onlyStrategist nonReentrant public returns (bytes memory, bytes memory){
        bool status;
        bytes memory result1;
        bytes memory result2;

        require(IFactory(factory).isAddressApprovedForDirectCallFunction(_address1, riskLevel), 'address1: directCallAddresses is not allowed');

        (status, result1) = _address1.call(_inuptBytes1); 
        require(status, 'call 1 failed');

        if(_address2 != address(0)){
            require(IFactory(factory).isAddressApprovedForDirectCallFunction(_address2, riskLevel), 'address2: directCallAddresses is not allowed');
            (status, result2) = _address2.call(_inuptBytes2); 
            require(status, 'call 2 failed');
        }

        return (result1, result2);
    }

    /**
    @notice emergency eth withdraw. Will take 10% fee.
    @param sendTo address where needed to send eth
    */
    function rescueEth(address payable sendTo) external onlyInvestor nonReentrant {

        uint256 balance = address(this).balance;
        require(balance > 0, 'nothing to rescue');
        sendTo.transfer(balance.sub(balance.div(10)));
        IFactory(factory).developmentFund().transfer(balance.div(10));

    }

    /** internal functions **/

    /**
    @notice convert any tokens to any tokens.
    @param _toWhomToIssue is address of personal contract for this user
    @param _tokenToExchange address of token witch will be converted
    @param _tokenToConvertTo address of token witch will be returned
    @param _amount how much will be converted
    */
    function convertTokenToToken(address _toWhomToIssue, address _tokenToExchange, address _tokenToConvertTo, uint256 _amount) internal returns (uint256) {

        address routerAddress = YZap(IFactory(factory).getContractToConvertTokens()).routerAddress();
        _approve(_tokenToExchange, routerAddress, _amount);

        uint256 length = (_tokenToExchange == networkNativeToken || networkNativeToken == _tokenToConvertTo)?2:3;
        address[] memory path = new address[](length);

        if(length == 3){
            path[0] = _tokenToExchange;
            path[1] = networkNativeToken;
            path[2] = _tokenToConvertTo;
        } else {//in case we don't need networkNativeToken token
            path[0] = _tokenToExchange;
            path[1] = _tokenToConvertTo;
        }

        return ITokenExchangeRouter(routerAddress).swapExactTokensForTokens(
            _amount,
            1,
            path,
            _toWhomToIssue,
            block.timestamp + 3600*24*365
        )[path.length - 1];
        //uint256 constant deadline = block.timestamp + 3600*24*365;//1 year

    }

    /**
    @notice Convert tokens to eth or wbnb
    @param _toWhomToIssue is address of personal contract for this user
    @param _tokenToExchange address of token witch will be converted
    @param _amount how much will be converted
    */
    function convertTokenToETH(address _toWhomToIssue, address _tokenToExchange, uint256 _amount) internal returns (uint256)  {

        address router = YZap(IFactory(factory).getContractToConvertTokens()).routerAddress();

        if(_tokenToExchange == networkNativeToken){
            //means we would like to exchange WETH(WBNB) to ETH(BNB)
            //IWBNBWETH(networkNativeToken).withdraw(_amount); - this reverts due to https://eips.ethereum.org/EIPS/eip-1884[EIP1884]
            //have to do this: WETH -> YIELD TOKEN -> ETH
            _approve(_tokenToExchange, router, _amount);
            _amount = convertTokenToToken(address(this), _tokenToExchange, yieldToken,  _amount);
            _tokenToExchange = yieldToken;
        }

        
            
        _approve(_tokenToExchange, router, _amount);

        address[] memory path = new address[](2);
        path[0] = _tokenToExchange;
        path[1] = networkNativeToken;//WETH or WBNB
        return ITokenExchangeRouter(router).swapExactTokensForETH(
            _amount,
            1,
            path,
            _toWhomToIssue,
            block.timestamp
        )[path.length - 1];
    }

    /**
    @notice Convert eth to token or wbnb
    @param _toWhomToIssue personal contract will work with pools only if their risk level is less than this variable. 0-100%
    @param _tokenToExchange personal contract will work with pools only if their risk level is less than this variable. 0-100%
    */
    function convertETHToToken(address _toWhomToIssue, address _tokenToExchange, uint256 _amount) internal returns (uint256)  {

        if(_tokenToExchange == networkNativeToken){
            //means we would like to exthange ETH(BNB) to WETH(WBNB)
            IWBNBWETH(networkNativeToken).deposit.value(_amount)();
            return _amount;
        }

        address router = YZap(IFactory(factory).getContractToConvertTokens()).routerAddress();

        address[] memory path = new address[](2);
        path[0] = networkNativeToken; //WETH or WBNB
        path[1] = _tokenToExchange; 
        return ITokenExchangeRouter(router).swapExactETHForTokens.value(_amount)(
            1,
            path,
            _toWhomToIssue,
            block.timestamp
        )[path.length - 1];
    }

    /**
    @notice convert array of any tokens to yield tokens.
    @param _toWhomToIssue is address of personal contract for this user
    @param _tokens array of token witch needed to convert to yield
    @return balance of yield tokens in this address 
    */
    function convertRewardTokensToYIELD(address _toWhomToIssue, address[] memory _tokens) internal returns (uint256) {
        
        for (uint256 i; i < _tokens.length; i++){
            //convertTokenToYIELD(_toWhomToIssue, _tokens[i], IERC20(_tokens[i]).balanceOf(address(this)));
            if(_tokens[i] != yieldToken){
                convertTokenToToken(_toWhomToIssue, _tokens[i], yieldToken, IERC20(_tokens[i]).balanceOf(address(this)));
            }
        }

        return IERC20(yieldToken).balanceOf(address(this));        
    }

    /**
    @notice add new pair to investment history.
    @param exchangeIndex index of new exchanges
    @param pairAddress address of new pair
    */
    function logNewPair(uint256 exchangeIndex, address pairAddress) internal {
        if(pairInvestmentHistory[pairAddress] == 0){
            Investments[exchangeIndex].push(pairAddress);
            pairInvestmentHistory[pairAddress] = exchangeIndex;
        }
    }

    function YZapOut(
        address _toWhomToIssue,
        uint256 _exchange,
        address _ToTokenContractAddress,
        address _fromPairAddress,
        uint256 _amount,
        uint256 _minTokensRec
    ) internal returns (uint256) {

        address outContractAddress = IFactory(factory).getOutContract(_exchange);

        address tokenAddress = IYZapOut(outContractAddress).getTokenAddressFromSwapAddress(_fromPairAddress); 
        _approve(tokenAddress, outContractAddress, _amount);

        return IYZapOut(outContractAddress).YZapOut(
            _toWhomToIssue,
            _ToTokenContractAddress,
            _fromPairAddress,
            _amount,
            _minTokensRec
        );
    }

    function _approve(address _token, address _spender, uint256 _amount) internal {

        if(_token == 0xdAC17F958D2ee523a2206206994597C13D831ec7){
            //USDT: https://github.com/Uniswap/uniswap-interface/issues/1172
            IERC20(_token).safeApprove(_spender, 0);
        }

        IERC20(_token).safeApprove(_spender, _amount);
    }

    function() external payable {
         emit ValueReceived(msg.sender, msg.value, address(0));
         IFactory(factory).generatePersonalContractEvent("ValueReceived", abi.encode(msg.value));
    }

}

pragma solidity ^0.5.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor () internal { }
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

pragma solidity ^0.5.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

pragma solidity ^0.5.0;

import "../../GSN/Context.sol";
import "./IERC20.sol";
import "../../math/SafeMath.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20Mintable}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20};
     *
     * Requirements:
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for `sender`'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner`s tokens.
     *
     * This is internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`.`amount` is then deducted
     * from the caller's allowance.
     *
     * See {_burn} and {_approve}.
     */
    function _burnFrom(address account, uint256 amount) internal {
        _burn(account, amount);
        _approve(account, _msgSender(), _allowances[account][_msgSender()].sub(amount, "ERC20: burn amount exceeds allowance"));
    }
}

pragma solidity ^0.5.0;

import "../../GSN/Context.sol";
import "./ERC20.sol";

/**
 * @dev Extension of {ERC20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
contract ERC20Burnable is Context, ERC20 {
    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev See {ERC20-_burnFrom}.
     */
    function burnFrom(address account, uint256 amount) public {
        _burnFrom(account, amount);
    }
}

pragma solidity ^0.5.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

pragma solidity ^0.5.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves.

        // A Solidity high level call has three parts:
        //  1. The target address is checked to verify it contains contract code
        //  2. The call itself is made, and success asserted
        //  3. The return value is decoded, which in turn checks the size of the returned data.
        // solhint-disable-next-line max-line-length
        require(address(token).isContract(), "SafeERC20: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

pragma solidity ^0.5.5;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following 
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }

    /**
     * @dev Converts an `address` into `address payable`. Note that this is
     * simply a type cast: the actual underlying value is not changed.
     *
     * _Available since v2.4.0._
     */
    function toPayable(address account) internal pure returns (address payable) {
        return address(uint160(account));
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     *
     * _Available since v2.4.0._
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-call-value
        (bool success, ) = recipient.call.value(amount)("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}

