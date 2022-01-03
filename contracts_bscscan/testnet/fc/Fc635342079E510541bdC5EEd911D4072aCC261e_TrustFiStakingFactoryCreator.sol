//// SPDX-License-Identifier: MIT
pragma solidity 0.7.4;
pragma experimental ABIEncoderV2;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/math/SafeMath.sol';
import '@openzeppelin/contracts/utils/Address.sol';
import '@openzeppelin/contracts/token/ERC20/SafeERC20.sol';
import './utils/constant.sol';
import './interface/BaseStruct.sol';
import './TrustFiStakingFactory.sol';

contract TrustFiStakingFactoryCreator is BaseStruct{

    /// @notice New ore pool contract: project manager, ore pool peripheral contract address, ore pool core contract address, whether to display in the front end
    event TrustFiStakingFactoryCreatorEvent(address indexed owner, address indexed factory, address indexed core, bool isVisible);

    /// @notice oldOwner: oldOwner, newOwner: newOwner
    event TransferOwnership(address indexed oldOwner, address indexed newOwner);

    /// @notice Clone template contract
    event CloneEvent(address indexed clone);

    /// @notice Support currency, create pool commission, supported or not
    event CommissionEvent(address indexed token, uint256 poolCommAmount,bool state);

    /// @notice Sets the factory template
    event PoolFactoryTemplateEvent(address indexed oldTemplate, address indexed newTemplate);

    /// @notice Sets the core template
    event CoreTemplateEvent(address indexed oldTemplate, address indexed newTemplate);

    /// @notice Sets the INVITE template
    event InviteTemplateEvent(address indexed oldTemplate, address indexed newTemplate);

    /// @notice Sets operation permission
    event OperateOwnerEvent(address indexed user, bool state);

    /// @notice Sets the financial permission
    event FinanceOwnerEvent(address indexed user, bool state);

    /// @notice receives all commissions
    event withdrawAllCommissionEvent(address indexed dst);

    /// @notice
    event withdrawCommissionEvent(address indexed dst,uint256 amount);

    /// @notice Creates a whitelist
    event WhiteListEvent(address indexed superAddr, bool state);

    /// @notice unStakeFeePercent
    event UnStakeFeePercentEvent(uint256 unStakeFeePercent);

    address public admin; // Platform administrator
    mapping(address => bool) public operateOwner; // Operation permission
    mapping(address => bool) public financeOwner; // Financial permissions
    mapping(address => bool) public whiteList; //Create a whitelist and create a pool for free

    struct Commission { // Commission structure
        uint256 poolCommAmount; // Create pool commission
        uint256 editFeeValue; // Edit fee (10,000 editFeeValue)
        uint256 closeFeeValue; // closeFeeValue closeFeeValue
        bool isSupported; // Supported or not
    }

    mapping(address => Commission) supportCommissions; // Commission collection
    address[] supportCommTokenArr; // Commission Tokens of support

    address public poolFactoryTemplate; // Factory template contract
    address public coreTemplate; // Core template contract

    uint256 public unStakeFeePercent;//Early unlock charge fee percentage

    mapping(address=> address) creatorFactories; // Project party => Mine pool factory
    mapping(address=> address) factoryCore; // Pool factory =>Core contract
    mapping(address=> uint256) poolIDRange; // Project party -> Pool ID range coefficient
    uint256 public rangeGlobal = 2000000; // The current range coefficient

    address[] internal allFactories; // All mine pool factories
    address internal constant ZERO = address(0);


    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    constructor(address _defaultPayToken,uint256 _defaultPoolCommAmount,uint256 _editFeeValue,uint256 _closeFeeValue,uint256 _unStakeFeePercent) {
        admin = msg.sender;
        _setOperateOwner(admin, true);
        unStakeFeePercent = _unStakeFeePercent;
        setSupportCommTokens(_defaultPayToken, _defaultPoolCommAmount,_editFeeValue,_closeFeeValue, true);
    }

    ////////////////////////////////////////////////////////////////////////////////////
     // Verify admin permission
    modifier onlyAdmin() {
        require(admin == msg.sender, "TrustFiStaking:FORBIDDEN_NOT_PLATFORM_ADMIN");
        _;
    }

    // Verify operation permissions
    modifier onlyOperater() {
        require(operateOwner[msg.sender], "TrustFiStaking:FORBIDDEN_NOT_OPERATER");
        _;
    }

    // Verify financial permissions
    modifier onlyFinanceOwner() {
        require(financeOwner[msg.sender], "TrustFiStaking:FORBIDDEN_NOT_FINANCE_OWNER");
        _;
    }

    // modify the owner
    function transferOwnership(address _admin) external onlyAdmin {
        require(ZERO != _admin, "TrustFiStaking:INVALID_ADDRESSES");
        emit TransferOwnership(admin, _admin);
        admin = _admin;
    }

    function _setOperateOwner(address user, bool state) internal {
        operateOwner[user] = state; // Set the operation permission
        emit OperateOwnerEvent(user, state);
    }

    // Set the operation permission
    function setOperateOwner(address user, bool state) external onlyAdmin {
        _setOperateOwner(user, state);
    }

    // Set financial permissions
    function setFinanceOwner(address user, bool state) external onlyAdmin {
        financeOwner[user] = state;
        emit FinanceOwnerEvent(user, state);
    }

    ////////////////////////////////////////////////////////////////////////////////////

    // Mine pool contract template for clone
    function setPoolFactoryTemplate(TrustFiStakingFactory _newTemplate) external onlyAdmin {
        require(ZERO != address(_newTemplate), "TrustFiStaking:INVALID_ADDRESSES");
        address oldFactoryTemp = poolFactoryTemplate;
        poolFactoryTemplate = address(_newTemplate);
        emit PoolFactoryTemplateEvent(oldFactoryTemp, poolFactoryTemplate);
    }

    // Core data template for clone
    function setCoreTemplate(address _newCore) external onlyAdmin {
        require(ZERO != _newCore, "TrustFiStaking:INVALID_ADDRESSES");
        address oldCoreTemp = coreTemplate;
        coreTemplate = _newCore;
        emit CoreTemplateEvent(oldCoreTemp, _newCore);
    }


    struct FactoryCreatorLocalVars {
        uint256 prePoolId;
        address token;
        address commissionToken;
        address pFactory;
        address core;
        uint256 commissionTotal;
        uint256 newTotal;
        uint256 balance;
        uint256 tvl;
        uint256 poolType;
        uint256 lockSeconds;
        uint256 maxStakeAmount;
        uint256 endTime;
        PoolStakeInfo poolStakeInfo;
        PoolRewardInfo poolRewardInfo;
        address feeAddress;
    }
    
    /**
        @notice creates a pool
        @param stakedToken Mine pool pledge currency
        @param commissionToken Specifies the currency of the fee
        @param poolParams poolType: 0 Specifies the type of the pool
            startBlock: 1 mining pool startBlock
            priority: 2 priority
            maxStakeAmount: 3 Maximum amount of pledge
            lockSeconds: 4 Number of seconds for locking a warehouse
            userMaxStakeAmount :5 Maximum amount of collateral (accumulated) for a user
            userMinStakeAmount :6 Minimum amount of collateral per user (per transaction)
            feeValue :7 early unlock fee (percent feeValue)
            editFeeValue :8 Editing fee (default is 0, background will automatically obtain)
            closeFeeValue :9 Close the handling fee (default is 0, the background will automatically obtain)
        @param rewardToken Mining Coins
        @param rewardTotals Number of mining bonus coins
        @param rewardPerBlocks Number of rewards per block
        @param poolViewParams name:0 Specifies the name of the pool to be displayed
            OfficialSite: 1 official website (optional)
            Twitter :2 Twitter (optional)
            Telegram:3 Telegram(Optional)
            StakedLogo :4 Staked coin Logo Address (optional)
            RewardLogo：5 Reward coin Logo Address (optional)
        @param feeAddress Address for charging early unlock fees
        @param pairs 0 stakedPair for calculate APR
            1 rewardPair for calculate APR
    */
    function createPool(
        address stakedToken,
        address commissionToken,
        uint256[] memory poolParams,
        address rewardToken,
        uint256 rewardTotals,
        uint256 rewardPerBlocks,
        string [] memory poolViewParams,
        address feeAddress,
        address [] memory pairs
    ) public {
        require(poolParams[0] < 4, "TrustFiStaking:INVALID_POOL_TYPE"); //poolType
        require(0 < rewardTotals, "TrustFiStaking:PARAMETER_ERROR_REWARD_TOTAL");
        require(0 < rewardPerBlocks, "TrustFiStaking:PARAMETER_ERROR_REWARD_PER_BLOCK");
        require(poolParams[5] <= poolParams[3], "TrustFiStaking:USER_MAX_STAKE_AMOUNT_MUST_LESS_THAN_MAX_STAKE_AMOUNT");
        require((ZERO != rewardToken) && (address(this) != rewardToken), "TrustFiStaking:PARAMETER_ERROR_TOKEN");
        require((ZERO != stakedToken) && (address(this) != stakedToken), "TrustFiStaking:STAKE_TOKEN_ERROR_TOKEN");
        require((ZERO != pairs[0]) && (address(this) != pairs[0]), "TrustFiStaking:STAKED_PAIR_ERROR_TOKEN");
        require((ZERO != pairs[1]) && (address(this) != pairs[1]), "TrustFiStaking:REWARD_PAIR_ERROR_TOKEN");

        FactoryCreatorLocalVars memory vars;
        vars.token = stakedToken;
        vars.commissionToken = commissionToken;
        Commission memory commTmp = supportCommissions[vars.commissionToken];
        require(commTmp.isSupported, "TrustFiStaking:COMMISSION_TOKEN_NOT_SUPPORTED");

        //add poolParams 8 9
        poolParams[8] = commTmp.editFeeValue; // Editing fee
        poolParams[9] = commTmp.closeFeeValue; // Close the processing fee

        vars.pFactory = creatorFactories[msg.sender];
        vars.commissionTotal = commTmp.poolCommAmount;

        if (vars.pFactory == ZERO) {
            vars.pFactory = createClone(poolFactoryTemplate);
            vars.core = createClone(coreTemplate);
            require(ZERO != vars.pFactory && ZERO != vars.core, "TrustFiStaking:CLONE_FACTORY_OR_CORE_FAILED_OR_INVITE_FAILED");
            rangeGlobal = rangeGlobal.add(1);
            poolIDRange[msg.sender] = rangeGlobal;
            TrustFiStakingFactory(vars.pFactory).initialize(msg.sender, address(this), vars.core);
            creatorFactories[msg.sender] = vars.pFactory;
            factoryCore[vars.pFactory] = vars.core;
            allFactories.push(vars.pFactory);
            emit TrustFiStakingFactoryCreatorEvent(msg.sender, vars.pFactory, vars.core, true);
        }
        if (!whiteList[msg.sender]) {
            if (vars.commissionTotal > 0) {
                IERC20(address(vars.commissionToken)).safeTransferFrom(msg.sender, address(this), vars.commissionTotal);
            }
        }
        vars.core = factoryCore[vars.pFactory];
        vars.balance = IERC20(rewardToken).balanceOf(vars.core);
        uint256 newTotals = rewardTotals;
        if (newTotals > 0) {
            IERC20(rewardToken).safeTransferFrom(msg.sender, vars.core, newTotals);
        }
        // Actual transfer to core amount, compatible with burning currency
        newTotals = IERC20(rewardToken).balanceOf(vars.core).sub(vars.balance);
        require((ZERO != vars.token) && (address(this) != vars.token) && (vars.pFactory != vars.token), "TrustFiStaking:PARAMETER_ERROR_TOKEN");
        uint256 range = poolIDRange[msg.sender].mul(DefaultSettings.EACH_FACTORY_POOL_MAX);
        TrustFiStakingFactory(vars.pFactory).addPool(range, vars.token,poolParams, rewardToken, newTotals, rewardPerBlocks,poolViewParams,feeAddress,vars.commissionToken,pairs);
    }


    /**
        @notice edit mine pool
        @param stakedToken Mine pool pledge currency
        @param poolParams poolType: 0 Specifies the type of the pool
            StartBlock: 1 mining pool startBlock
            Priority: 2 priority
            MaxStakeAmount: 3 Maximum amount of pledge (hard top)
            LockSeconds: 4 Number of seconds for locking a warehouse
            UserMaxStakeAmount :5 Maximum amount of collateral (accumulated) for a user
            UserMinStakeAmount :6 Minimum amount of collateral per user (per transaction)
            FeeValue :7 early unlock fee (percent feeValue)
            EditFeeValue :8 Editing fee (default is 0, background will automatically obtain)
            CloseFeeValue :9 Close the handling fee (default is 0, the background will automatically obtain)
        @param rewardToken Mining Coins
        @param rewardTotals Number of mining bonus coins
        @param rewardPerBlocks Number of rewards per block
        @param poolViewParams name:0 Specifies the name of the pool to be displayed
            OfficialSite: 1 official website (optional)
            Twitter :2 Twitter (optional)
            Telegram:3 Telegram(Optional)
            StakedLogo :4 Staked coin Logo Address (optional)
            RewardLogo :5 Reward coin Logo Address (optional)
        @param feeAddress Address for charging early unlock fees
        @param pairs 0 stakedPair for calculate APR
            1 rewardPair for calculate APR
    */
    function editPool(
        uint256 poolId,
        address stakedToken,
        uint256[] memory poolParams,
        address rewardToken,
        uint256 rewardTotals,
        uint256 rewardPerBlocks,
        string [] memory poolViewParams,
        address feeAddress,
        address [] memory pairs
    ) public {
        require(poolParams[0] < 4, "TrustFiStaking:INVALID_POOL_TYPE"); //poolType
        require(0 < rewardTotals, "TrustFiStaking:PARAMETER_ERROR_REWARD_TOTAL");
        require(0 < rewardPerBlocks, "TrustFiStaking:PARAMETER_ERROR_REWARD_PER_BLOCK");
        require(poolParams[5] <= poolParams[3], "TrustFiStaking:USER_MAX_STAKE_AMOUNT_MUST_LESS_THAN_MAX_STAKE_AMOUNT");
        require((ZERO != stakedToken) && (address(this) != stakedToken), "TrustFiStaking:PARAMETER_ERROR_TOKEN");

        FactoryCreatorLocalVars memory vars;
        vars.token = stakedToken;
        vars.pFactory = creatorFactories[msg.sender];
        vars.core = factoryCore[vars.pFactory];

        require(ZERO != vars.pFactory && ZERO != vars.core, "TrustFiStaking:CLONE_FACTORY_OR_CORE_FAILED_OR_INVITE_FAILED");

        ITrustFiStakingFactoryCore core = ITrustFiStakingFactoryCore(vars.core);
        vars.poolStakeInfo = core.getPoolStakeInfo(poolId);
        require((ZERO != vars.poolStakeInfo.token) && (vars.poolStakeInfo.startBlock > block.number), "TrustFiStaking:POOL_NOT_EXIST_OR_MINT_HAS_START"); // Whether mining has not started yet
        vars.feeAddress = feeAddress;

        // Editing fees are charged
        if (!whiteList[msg.sender]) {
            if (vars.poolStakeInfo.editFeeValue > 0) {
                require(IERC20(address(vars.poolStakeInfo.commissionToken)).balanceOf(msg.sender) >= vars.poolStakeInfo.editFeeValue,"TrustFiStaking:COMMISSIONTOKEN NOT ENOUGH");
                IERC20(address(vars.poolStakeInfo.commissionToken)).safeTransferFrom(msg.sender, address(this), vars.poolStakeInfo.editFeeValue);
            }
        }
        // Handle editing addition and subtraction
        vars.newTotal = rewardTotals;
        vars.poolRewardInfo  = core.getPoolRewardInfo(poolId);
        vars.balance = IERC20(rewardToken).balanceOf(vars.core);
        // Determine whether to increase, decrease, or remain the same
        uint256 oldRewardTotals = 0;
        if(vars.poolRewardInfo.token == rewardToken){
            oldRewardTotals = vars.poolRewardInfo.rewardTotal;
        }else{// Return all old rewardToken
            TrustFiStakingFactory(vars.pFactory).platformSafeTransfer(vars.poolRewardInfo.token,msg.sender,vars.poolRewardInfo.rewardTotal);
        }
        if(vars.newTotal > oldRewardTotals){// add
            require(IERC20(rewardToken).balanceOf(msg.sender) >= vars.newTotal.sub(oldRewardTotals),"TrustFiStaking:TOKEN NOT ENOUGH");
            IERC20(rewardToken).safeTransferFrom(msg.sender, vars.core, vars.newTotal.sub(oldRewardTotals));
             //Actual transfer to core amount, compatible with burning currency
            vars.newTotal = oldRewardTotals.add(IERC20(rewardToken).balanceOf(vars.core).sub(vars.balance));
        }else if(vars.newTotal < oldRewardTotals){//sub
            TrustFiStakingFactory(vars.pFactory).platformSafeTransfer(rewardToken,msg.sender,oldRewardTotals.sub(vars.newTotal));
        }

        TrustFiStakingFactory(vars.pFactory).editPool(poolId, vars.token,poolParams, rewardToken, vars.newTotal, rewardPerBlocks,poolViewParams,vars.feeAddress,pairs);
    }

    /**
    Closed mine pool
    */
    function closePool(uint256 poolId) public {
        FactoryCreatorLocalVars memory vars;
        vars.pFactory = creatorFactories[msg.sender];
        vars.core = factoryCore[vars.pFactory];
        require(ZERO != vars.pFactory && ZERO != vars.core, "TrustFiStaking:CLONE_FACTORY_OR_CORE_FAILED_OR_INVITE_FAILED");
        ITrustFiStakingFactoryCore core = ITrustFiStakingFactoryCore(vars.core);
        vars.poolStakeInfo = core.getPoolStakeInfo(poolId);
        require((ZERO != vars.poolStakeInfo.token) && (vars.poolStakeInfo.startBlock > block.number), "TrustFiStaking:POOL_NOT_EXIST_OR_MINT_HAS_START"); // haven't started mining yet
        vars.poolRewardInfo  = core.getPoolRewardInfo(poolId);

        //Return fee
        if (!whiteList[msg.sender]) {
            if (vars.poolStakeInfo.closeFeeValue > 0) {
                require(IERC20(address(vars.poolStakeInfo.commissionToken)).balanceOf(address(this)) >= vars.poolStakeInfo.closeFeeValue,"TrustFiStaking:COMMISSIONTOKEN NOT ENOUGH");
                IERC20(address(vars.poolStakeInfo.commissionToken)).safeTransfer(msg.sender, vars.poolStakeInfo.closeFeeValue);
            }
        }
        //Return all yield rewardToken
        TrustFiStakingFactory(vars.pFactory).platformSafeTransfer(vars.poolRewardInfo.token,msg.sender,vars.poolRewardInfo.rewardTotal);

        TrustFiStakingFactory(vars.pFactory).closePool(poolId);
    }

    /**
        @notice One button to claim revenue
        @param factoryArr Array of pool contracts
     */
    function withdrawAllRewards(TrustFiStakingFactory[] memory factoryArr) external {
        for (uint256 i = 0; i < factoryArr.length; i++) {
            TrustFiStakingFactory factory = factoryArr[i];
            factory.withdrawRewards2(factory.poolIds(), msg.sender);
        }
    }

    /**
      * Get the amount of fees obtained
      * (tokens, amounts) Support commission currency, current holding quantity
     */
    function getBalance() external view returns (address[] memory tokens, uint256[] memory amounts) {
        uint256[] memory balances = new uint256[](supportCommTokenArr.length);
        for (uint256 i = 0; i < supportCommTokenArr.length; i++) {
            uint256 b = IERC20(address(supportCommTokenArr[i])).balanceOf(address(this));
            balances[i] = b;
        }

        tokens = supportCommTokenArr;
        amounts = balances;
    }

    /**
        @notice Get all mine pool factories
        @return All Plant contracts
     */
    function getAllFactories() external view returns (address[] memory) {
        return allFactories;
    }

    /**
        @notice Gets the pool factory created by the current user
        @param user User address
        @return Specifies the mining pool contract held by the current user
    */
    function getMyFactory(address user) external view returns (address) {
        return creatorFactories[user];
    }

    /**
        @notice Gets the currency and state in which payment is supported
     */
    function getSupportCommTokens() external view returns (address[] memory supportCommTokenArrRet, uint256[] memory poolAmounts,uint256[] memory editFeeValue,uint256[] memory closeFeeValue, bool[] memory states) {
        supportCommTokenArrRet = new address[](supportCommTokenArr.length);
        poolAmounts = new uint256[](supportCommTokenArr.length);
        editFeeValue = new uint256[](supportCommTokenArr.length);
        closeFeeValue = new uint256[](supportCommTokenArr.length);
        states = new bool[](supportCommTokenArr.length);
        for (uint256 i = 0; i < supportCommTokenArr.length; i++) {
            supportCommTokenArrRet[i] = supportCommTokenArr[i];
            poolAmounts[i] = supportCommissions[supportCommTokenArr[i]].poolCommAmount;
            editFeeValue[i] = supportCommissions[supportCommTokenArr[i]].editFeeValue;
            closeFeeValue[i] = supportCommissions[supportCommTokenArr[i]].closeFeeValue;
            states[i] = supportCommissions[supportCommTokenArr[i]].isSupported;
        }
    }

    /**
        @notice Gets the quantity of mine pool contract
        @return Number of all mine pool contracts
    */
    function getFactoryCounts() external view returns(uint256) {
        return allFactories.length;
    }

    /**
        @notice Sets the currency and quantity of payment
        @param _token Supports commission currencies
        @param _poolCommAmount The cost of creating a pool
        @param _editFeeValue edit mine pool fees
        @param _closeFeeValue Cost of creating a mine pool
        @param _state Indicates the currency status
    */
    function setSupportCommTokens(address _token, uint256 _poolCommAmount,uint256 _editFeeValue,uint256 _closeFeeValue, bool _state) public onlyOperater {
        require(ZERO != _token, "TrustFiStaking:INVALID_ADDRESS");
        Commission memory comm;
        comm.poolCommAmount = _poolCommAmount;
        comm.editFeeValue = _editFeeValue; //Editing fee
        comm.closeFeeValue = _closeFeeValue; //Closing pool fees
        comm.isSupported = _state;
        supportCommissions[_token] = comm;

        emit CommissionEvent(_token, _poolCommAmount, _state);
        for (uint256 i = 0; i < supportCommTokenArr.length; i++) {
            if (_token == supportCommTokenArr[i]) {
                return;
            }
        }
        supportCommTokenArr.push(_token);
    }

    /**
        @notice Get all commissions in one click
        @param _dst Address for receiving commissions
    */
    function withdrawAllCommission(address _dst) external onlyFinanceOwner {
        require(ZERO != _dst, "TrustFiStaking:INVALID_ADDRESS");
        for (uint256 i = 0; i < supportCommTokenArr.length; i++) {
            uint256 b = IERC20(supportCommTokenArr[i]).balanceOf(address(this));
            if (b > 0) {
                IERC20(supportCommTokenArr[i]).safeTransfer(_dst, b);
            }
        }
        emit withdrawAllCommissionEvent(_dst);
    }

    /**
        @notice Receive specified token, specified amount of commission
        @param token token address
        @param _dst Address for receiving commissions
        @param amount Amount of commission received
    */
    function withdrawCommission(address token,address _dst,uint256 amount) external onlyFinanceOwner {
        require(ZERO != _dst, "TrustFiStaking:INVALID_ADDRESS");
        uint256 b = IERC20(token).balanceOf(address(this));
        require(b > amount, "TrustFiStaking:INVALID_TOKEN_AMOUNT");
        IERC20(token).safeTransfer(_dst, amount);
        emit withdrawCommissionEvent(_dst,amount);
    }

    /**
        @notice Changes the name of the mine pool
        @param _creator Project side
        @param _poolId ID of a mine pool
        @param _name New name of the pool
    */
    function setName(address _creator, uint256 _poolId, string memory _name) external onlyOperater {
        ITrustFiStakingFactoryCore core = ITrustFiStakingFactoryCore(getCore(_creator));
        core.checkPIDValidation(_poolId);
        core.setName(_poolId, _name);
    }


    /**
        @notice Changes the sorting of ore pools
        @param _creator Project side
        @param _poolId ID of a mine pool
        @param _priority New priority
    */
    function setPriority(address _creator, uint256 _poolId, uint256 _priority) external onlyOperater {
        ITrustFiStakingFactoryCore core = ITrustFiStakingFactoryCore(getCore(_creator));
        core.checkPIDValidation(_poolId);
        core.setPriority(_poolId, _priority);
    }

    function getCore(address _creator) internal view returns(address) {
        address factory = creatorFactories[_creator];
        require(ZERO != factory, "TrustFiStaking:CREATOR_FACTORY_NOT_FOUND");
        return factoryCore[factory];
    }

    /**
        @notice Creates a whitelist
        @param _super Whitelist
        @param _state Whitelist status
    */
    function setWhiteList(address _super, bool _state) external onlyOperater {
        require(ZERO != _super, "TrustFiStaking:INVALID_ADDRESS");
        whiteList[_super] = _state;
        address factory = creatorFactories[_super];
        if(ZERO != factory) {
            TrustFiStakingFactory(factory).setWhiteList(_super, _state);
        }
        emit WhiteListEvent(_super, _state);
    }

    /**
        @notice set new UnStakeFeePercent
        @param _unStakeFeePercent unStake Fee Percent (0~100)
    */
    function setUnStakeFeePercent(uint256 _unStakeFeePercent) external onlyOperater{
        require(_unStakeFeePercent >=0 && _unStakeFeePercent <= 100,"TrustFiStaking:UN_STAKE_FEE_PERCENT ERROR");
        unStakeFeePercent = _unStakeFeePercent;
        emit UnStakeFeePercentEvent(unStakeFeePercent);
    }

    /**
        @notice get UnStakeFeePercent
    */
    function getUnStakeFeePercent() external view returns(uint256) {
        return unStakeFeePercent;
    }

    /**
        @notice Queries whether the system is in the whitelist
        @param _creator Whitelist
    */
    function isWhiteList(address _creator) external view returns(bool) {
        return whiteList[_creator];
    }

    /**
        @notice Clone template contract
        @param _prototype Clone template
        @return proxy new contract
    */
    function createClone(address _prototype) internal returns (address proxy) {
        bytes20 targetBytes = bytes20(_prototype);
        assembly {
            let clone := mload(0x40)
            mstore(clone, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(clone, 0x14), targetBytes)
            mstore(
            add(clone, 0x28),
            0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000
            )
            proxy := create(0, clone, 0x37)
        }

        emit CloneEvent(proxy);
        return proxy;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
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
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

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
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
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
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.4;

library ErrorCode {

    string constant FORBIDDEN = 'FORBIDDEN';
    string constant IDENTICAL_ADDRESSES = 'IDENTICAL_ADDRESSES';
    string constant ZERO_ADDRESS = 'ZERO_ADDRESS';
    string constant INVALID_ADDRESSES = 'INVALID_ADDRESSES';
    string constant BALANCE_INSUFFICIENT = 'BALANCE_INSUFFICIENT';
    string constant REWARDTOTAL_LESS_THAN_REWARDPROVIDE = 'REWARDTOTAL_LESS_THAN_REWARDPROVIDE';
    string constant PARAMETER_TOO_LONG = 'PARAMETER_TOO_LONG';
    string constant REGISTERED = 'REGISTERED';
    string constant MINING_NOT_STARTED = 'MINING_NOT_STARTED';
    string constant END_OF_MINING = 'END_OF_MINING';
    string constant POOL_NOT_EXIST_OR_END_OF_MINING = 'POOL_NOT_EXIST_OR_END_OF_MINING';
    
}

library DefaultSettings {
    uint256 constant EACH_FACTORY_POOL_MAX = 10000; //Each mine pool contract creates a contract upper limit
    uint256 constant SECONDS_PER_DAY = 86400; //Number of seconds a day
    uint256 constant ONEMINUTE = 1 minutes;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.4;
pragma experimental ABIEncoderV2;

interface BaseStruct {

    /** There are four types of ore pools */
     enum PoolLockType {
        SINGLE_TOKEN, // Single coin mining
        LP_TOKEN, // lp dig
        SINGLE_TOKEN_FIXED, // single currency regular mining
        LP_TOKEN_FIXED // LP regular mining
    }

    /** Mineral pool visualization information */
    struct PoolViewInfo {
        address token; // Token contract address
        string name; // name
        uint256 priority; // sorting
        string officialSite; // official website (optional)
        string twitter; // Twitter (optional)
        string telegram; // Telegram(optional)
        string stakedLogo; // Staked coin Logo Address (optional)
        string rewardLogo; // Reward coin Logo Address (optional)
        address stakedPair; // stakedPair for calculate APR
        address rewardPair; // rewardPair for calculate APR
    }

    /** Ore pool pledge information */
    struct PoolStakeInfo {
        uint256 startBlock; // Mining starts block high
        address token; // Token contract address, single coin, lp is the same
        uint256 amount; // Pledge quantity, this is TVL
        uint256 participantCounts; // The number of players participating in the pledge
        PoolLockType poolType; // Single coin mining, LP mining, single coin periodic, LP periodic
        uint256 lockSeconds; // The duration of the lock
        uint256 lastRewardBlock; // Finally issue the bonus block height
        uint256 totalPower; // on the whole
        uint256 maxStakeAmount; // Maximum amount of pledge
        uint256 endBlock; // End of mining block high
        uint256 endTime; // Mining end time
        uint256 userMaxStakeAmount; // Maximum number of mortgages per user
        uint256 userMinStakeAmount; // Minimum number of mortgages per user
        uint256 feeValue; // Early unlock fee (10,000 feeValue)
        address feeAddress; // Charge the unlock fee address
        uint256 editFeeValue; // Editing fee
        uint256 closeFeeValue; // Close the pool fee
        address commissionToken;//commissionToken
    }

    /** Mine pool bonus information */
    struct PoolRewardInfo {
        address token; // Mining reward currency :A/B/C
        uint256 rewardTotal; // Total pool reward
        uint256 rewardPerBlock; // Single block reward
        uint256 rewardProvide; // The mine pool has been awarded
        uint256 rewardPerShare; // Unit count power reward
    }

    /** User pledges information */
    struct UserStakeInfo {
        uint256 startBlock; // Pledge start block height
        uint256 amount; // Pledge quantity
        uint256 stakePower; // pledge the power
        uint256 lastStakeTime; // The time of the last mortgage
        uint256 stakeRewardDebts; // Pledge debt
        uint256 stakeClaimedRewards; // Have received pledge reward
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.4;
pragma experimental ABIEncoderV2;

import '@openzeppelin/contracts/math/SafeMath.sol';
import '@openzeppelin/contracts/token/ERC20/SafeERC20.sol';
import './interface/ITrustFiStakingFactory.sol';
import './utils/constant.sol';
import './interface/ITrustFiStakingFactoryCore.sol';


contract TrustFiStakingFactory is ITrustFiStakingFactory {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    bool initialized;
    address private constant ZERO = address(0);

    address public owner; //All permissions
    address internal platform; //platform

    ITrustFiStakingFactoryCore public core; //core contract
    mapping(address => bool) public operateOwner; //Operation permissions
    mapping(uint256 => uint256) public lastSetRewardPerBlockTime; //Set the last time for block reward count，poolid->timestamp

    mapping(address => bool) public whiteList; //Create people whitelist, can increase APR for free, delay mine pool

    //Verifying owner Rights
    modifier onlyOwner() {
        require(owner == msg.sender, "TrustFiStaking:FORBIDDEN_NOT_OWNER");
        _;
    }

    //Verifying Platform Rights
    modifier onlyPlatform() {
        require(platform == msg.sender, "TrustFiStaking:FORBIDFORBIDDEN_NOT_PLATFORM");
        _;
    }

    //Verifying operation Rights
    modifier onlyOperater() {
        require(operateOwner[msg.sender], "TrustFiStaking:FORBIDDEN_NOT_OPERATER");
        _;
    }

    /**
    @notice Clone TrustFiStakingFactory initialization
    @param _owner Project party
    @param _platform FactoryCreator platform
    @param _core Clone Core contract
    */
    function initialize(address _owner, address _platform, address _core) external {
        require(!initialized,  "TrustFiStaking:ALREADY_INITIALIZED!");
        initialized = true;
        core = ITrustFiStakingFactoryCore(_core);
        core.initialize(address(this), _platform);

        owner = _owner; //The owner permissions
        platform = _platform; //Platform permissions

        _setOperateOwner(_owner, true);
    }

    /**
    @notice Transfers owner rights
    @param oldOwner: oldOwner
    @param newOwner: newOwner
     */
    event TransferOwnership(address indexed oldOwner, address indexed newOwner);

    /**
    @notice Sets operation rights
    @param user: Business address
    @param state: Permission status
     */
    event OperateOwnerEvent(address indexed user, bool state);

    /**
     @notice change OWNER
     @param _owner：new Owner
     */
    function transferOwnership(address _owner) external override onlyOwner {
        require(ZERO != _owner, "TrustFiStaking:INVALID_ADDRESSES");
        emit TransferOwnership(owner, _owner);
        owner = _owner;
    }

    /**
    Setting Operation Rights
     */
    function setOperateOwner(address user, bool state) external override onlyOwner {
        _setOperateOwner(user, state);
    }

    /**
    @notice Sets operation rights
    @param user Business address
    @param state Permission status
     */
    function _setOperateOwner(address user, bool state) internal {
        operateOwner[user] = state; //Setting Operation Rights
        emit OperateOwnerEvent(user, state);
    }

    ////////////////////////////////////////////////////////////////////////////////////
    /**
    @notice pledge
    @param poolId pledges mine pool
    @param amount Amount pledged
    */
    function stake(uint256 poolId, uint256 amount) external override {
        BaseStruct.PoolStakeInfo memory poolStakeInfo = core.getPoolStakeInfo(poolId);
        require((ZERO != poolStakeInfo.token) && (poolStakeInfo.startBlock <= block.number), "TrustFiStaking:POOL_NOT_EXIST_OR_MINT_NOT_START"); //Whether to start mining
        if(poolStakeInfo.maxStakeAmount > 0){//There is a hard top set
            require(poolStakeInfo.amount.add(amount) <= poolStakeInfo.maxStakeAmount, "TrustFiStaking:STAKE_AMOUNT_TOO_LARGE");
        }
        if(poolStakeInfo.userMinStakeAmount >0){//There is a set user minimum amount of mortgage at a time
            require(poolStakeInfo.userMinStakeAmount <= amount, "TrustFiStaking:STAKE_AMOUNT_TOO_SMALL");
        }
        if(poolStakeInfo.userMaxStakeAmount > 0){//Set the accumulative mortgage number of users
            BaseStruct.UserStakeInfo memory userStakeInfo = core.getUserStakeInfo(poolId, msg.sender);
            require(userStakeInfo.amount.add(amount) <= poolStakeInfo.userMaxStakeAmount, "TrustFiStaking:USER_MAX_STAKE_AMOUNT_INSUFFICIENT");
        }

        uint256 balance = IERC20(poolStakeInfo.token).balanceOf(address(core));
        IERC20(poolStakeInfo.token).safeTransferFrom(msg.sender, address(core), amount); //Transfer the sender's pledge to this
        //Actual transfer to core amount, compatible with burning currency
        amount = IERC20(poolStakeInfo.token).balanceOf(address(core)).sub(balance);
        core.stake(poolId, amount, msg.sender);
    }

    /**
    @notice pledge
    @param poolId Unpledge mine pool
    @param amount Amount of unpledged pledges
     */
    function unStake(uint256 poolId, uint256 amount) external override {
        checkOperationValidation(poolId);
        BaseStruct.UserStakeInfo memory userStakeInfo = core.getUserStakeInfo(poolId, msg.sender);
        require((amount > 0) && (userStakeInfo.amount >= amount), "TrustFiStaking:BALANCE_INSUFFICIENT");
        core._unStake(poolId, amount, msg.sender);
    }

    /**
    @notice Batch unpledge and extract rewards
    @param _poolIds Unpledge mine pool
     */
    function unStakes(uint256[] memory _poolIds) external override {
        require((0 < _poolIds.length) && (50 >= _poolIds.length), "TrustFiStaking:PARAMETER_ERROR_TOO_SHORT_OR_LONG");
        uint256 amount;
        uint256 poolId;
        BaseStruct.UserStakeInfo memory userStakeInfo;

        for (uint256 i = 0; i < _poolIds.length; i++) {
            poolId = _poolIds[i];
            checkOperationValidation(poolId);
            userStakeInfo = core.getUserStakeInfo(poolId, msg.sender);
            amount = userStakeInfo.amount; //The number of pledges for the sender

            if (0 < amount) {
                core._unStake(poolId, amount, msg.sender);
            }
        }
    }

    /**
    @notice Extract the reward
    @param poolId pool id
     */
    function withdrawReward(uint256 poolId) public override {
        checkOperationValidation(poolId);
        core._withdrawReward(poolId, msg.sender);
    }

    /**
    Batch extract rewards for use by the platform
     */
    function withdrawRewards2(uint256[] memory _poolIds, address user) external onlyPlatform override {
        for (uint256 i = 0; i < _poolIds.length; i++) {
            BaseStruct.PoolStakeInfo memory poolStakeInfo = core.getPoolStakeInfo(_poolIds[i]);
            if (poolStakeInfo.startBlock > block.number ) {
                continue;
            }
            core._withdrawReward(_poolIds[i], user);
        }
    }

    /**
    Verify the validity of re-& & opening lockers
     */
     function checkOperationValidation(uint256 poolId) internal view {
        BaseStruct.PoolStakeInfo memory poolStakeInfo = core.getPoolStakeInfo(poolId);
        require((ZERO != poolStakeInfo.token), "TrustFiStaking:POOL_NOT_EXIST"); //Whether to start mining require( (poolStakeInfo.startBlock <= block.number), "TrustFiStaking:POOL_NOT_START"); //Whether to start mining

     }

    struct PendingLocalVars {
        uint256 poolId;
        address user;
        uint256 stakeReward;
        uint256 rewardPre;
    }

    /**
    Tokens to be received
     */
    function pendingRewardV3(uint256 poolId, address user) external view override returns (
                            address tokens,
                            uint256 stakePendingRewardsRet,
                            uint256 stakeClaimedRewardsRet) {
        PendingLocalVars memory vars;
        vars.poolId = poolId;
        vars.user = user;
        tokens = ZERO;
        stakePendingRewardsRet = 0;
        stakeClaimedRewardsRet = 0;
        BaseStruct.PoolStakeInfo memory poolStakeInfo = core.getPoolStakeInfo(vars.poolId);
        if (ZERO != poolStakeInfo.token) {
            BaseStruct.UserStakeInfo memory userStakeInfo = core.getUserStakeInfo(vars.poolId,vars.user);

            BaseStruct.PoolRewardInfo memory poolRewardInfo = core.getPoolRewardInfo(vars.poolId);

            if (0 < poolStakeInfo.totalPower) {
                //RewardPerShare may be increased if mining starts before the pool is finished or restarted
                if (block.number > poolStakeInfo.lastRewardBlock) {
                    vars.rewardPre = block.number.sub(poolStakeInfo.lastRewardBlock).mul(poolRewardInfo.rewardPerBlock); //Waiting for snapshots reward
                    if (poolRewardInfo.rewardProvide.add(vars.rewardPre) >= poolRewardInfo.rewardTotal) {
                        vars.rewardPre = poolRewardInfo.rewardTotal.sub(poolRewardInfo.rewardProvide); //Reduction exceeds reward
                    }
                    poolRewardInfo.rewardPerShare = poolRewardInfo.rewardPerShare.add(vars.rewardPre.mul(1e24).div(poolStakeInfo.totalPower)); //Accumulates the bonus unit of force to be taken
                }
            }

            //Count old reward currencies
            vars.stakeReward = userStakeInfo.stakePower.mul(poolRewardInfo.rewardPerShare).sub(userStakeInfo.stakeRewardDebts).div(1e24); //Pledge reward for snapshots to be taken
            stakeClaimedRewardsRet = userStakeInfo.stakeClaimedRewards; //Pledge reward received (cumulative)

            stakePendingRewardsRet = vars.stakeReward;
            tokens = poolRewardInfo.token;

        }
    }

    /**
    poolID
     */
    function poolIds() external view override returns (uint256[] memory poolIDs) {
        poolIDs = core.getPoolIds();
    }

    /**
    Scope of pledge quantity
     */
    function stakeRange(uint256 poolId) external view override returns (uint256 minStakeAmount, uint256 maxStakeAmount) {
        BaseStruct.PoolStakeInfo memory poolStakeInfo = core.getPoolStakeInfo(poolId);
        if (ZERO == poolStakeInfo.token) {
            return (0, 0);
        }
        minStakeAmount = poolStakeInfo.userMinStakeAmount;
        maxStakeAmount = 0;
        if(poolStakeInfo.maxStakeAmount > 0){//There is a hard top set
            if(poolStakeInfo.amount < poolStakeInfo.maxStakeAmount ){
                maxStakeAmount = poolStakeInfo.maxStakeAmount.sub(poolStakeInfo.amount);
            }
        }
    }

    /**
    User pledge quantity range
    */
    function userStakeRange(uint256 poolId,address user) external view override returns (uint256 userMinStakeAmount, uint256 userMaxStakeAmount) {
        BaseStruct.PoolStakeInfo memory poolStakeInfo = core.getPoolStakeInfo(poolId);
        BaseStruct.UserStakeInfo memory userStakeInfo = core.getUserStakeInfo(poolId,user);
        if (ZERO == poolStakeInfo.token) {
            return (0, 0);
        }
        userMinStakeAmount = poolStakeInfo.userMinStakeAmount;
        userMaxStakeAmount = 0;

        if(poolStakeInfo.userMaxStakeAmount >0){
            if(poolStakeInfo.maxStakeAmount >0){
                if(poolStakeInfo.userMaxStakeAmount > userStakeInfo.amount){
                    userMaxStakeAmount = poolStakeInfo.userMaxStakeAmount.sub(userStakeInfo.amount);
                    uint256 maxStakeAmountRest = poolStakeInfo.maxStakeAmount.sub(poolStakeInfo.amount);
                    if(maxStakeAmountRest < userMaxStakeAmount){
                        userMaxStakeAmount = maxStakeAmountRest;
                    }
                }
            }else{
                if(poolStakeInfo.userMaxStakeAmount > userStakeInfo.amount){
                    userMaxStakeAmount = poolStakeInfo.userMaxStakeAmount.sub(userStakeInfo.amount);
                }
            }

        }else{
            if(poolStakeInfo.maxStakeAmount >0){
                userMaxStakeAmount = poolStakeInfo.maxStakeAmount.sub(userStakeInfo.amount);
            }
        }

    }

    /*
    Pool name, pledge currency, charge fee address, total lock-up, number of addresses, pool type, lock-up time, start block, end time, advance unlock fee
    */
    function getPoolStakeDetail(uint256 poolId) external view override returns
    (string memory name, address token, address feeAddress, uint256 stakeAmount, uint256 participantCounts, uint256 poolType, uint256 lockSeconds,
        uint256 startBlock, uint256 endTime, uint256 feeValue) {
        PoolStakeInfo memory poolStakeInfo = core.getPoolStakeInfo(poolId);
        PoolViewInfo memory poolViewInfo = core.getPoolViewInfo(poolId);

        name = poolViewInfo.name;
        token = poolStakeInfo.token;
        startBlock = poolStakeInfo.startBlock;
        stakeAmount = poolStakeInfo.amount;
        participantCounts = poolStakeInfo.participantCounts;
        poolType = uint256(poolStakeInfo.poolType);
        lockSeconds = poolStakeInfo.lockSeconds;
        endTime = poolStakeInfo.endTime;
        feeValue = poolStakeInfo.feeValue;
        feeAddress = poolStakeInfo.feeAddress;

    }

    /**Details of user pledge */
    function getUserStakeInfo(uint256 poolId, address user) external view override returns (
                        uint256 startBlock, 
                        uint256 stakeAmount, 
                        uint256 stakePower) {
        BaseStruct.UserStakeInfo memory userStakeInfo = core.getUserStakeInfo(poolId,user);
        startBlock = userStakeInfo.startBlock;
        stakeAmount = userStakeInfo.amount;
        stakePower = userStakeInfo.stakePower;
    }

    /*
    To obtain award details
    */
    function getUserRewardInfo(uint256 poolId, address user) external view override returns (
                        uint256 stakeRewardDebt) {
        BaseStruct.UserStakeInfo memory userStakeInfo = core.getUserStakeInfo(poolId,user);
        stakeRewardDebt = userStakeInfo.stakeRewardDebts;
    }

    /**
    Get mining bonus details
    */
    function getPoolRewardInfo(uint poolId) external view override returns (PoolRewardInfo memory) {
        return core.getPoolRewardInfo(poolId);
    }

    /* 
    Get more coins bonus details
    */
    function getPoolRewardInfoDetail(uint256 poolId) external view override returns (
                        address tokens,
                        uint256 rewardTotals,
                        uint256 rewardProvides,
                        uint256 rewardPerBlocks,
                        uint256 rewardPerShares) {
        BaseStruct.PoolRewardInfo memory _poolRewardInfos = core.getPoolRewardInfo(poolId);

        BaseStruct.PoolStakeInfo memory poolStakeInfo = core.getPoolStakeInfo(poolId);
        uint256 newRewards;
        uint256 blockCount;
        if(block.number > poolStakeInfo.lastRewardBlock) { //Has yet to reopen
            blockCount = block.number.sub(poolStakeInfo.lastRewardBlock); //Number of blocks to be issued
        }

        newRewards = blockCount.mul(_poolRewardInfos.rewardPerBlock); //Total bonus between snapshots
        tokens = _poolRewardInfos.token;
        rewardTotals = _poolRewardInfos.rewardTotal;

        if (_poolRewardInfos.rewardProvide.add(newRewards) > rewardTotals) {
            rewardProvides = rewardTotals;
        } else {
            rewardProvides = _poolRewardInfos.rewardProvide.add(newRewards);
        }

        rewardPerBlocks = _poolRewardInfos.rewardPerBlock;
        rewardPerShares = _poolRewardInfos.rewardPerShare;

    }

    /** 
    new Pool
    */
    function addPool(
        uint256 range,
        address stakedToken ,
        uint256[] memory poolParams,
        address rewardToken,
        uint256 rewardTotals,
        uint256 rewardPerBlocks,
        string [] memory poolViewParams,
        address feeAddress,
        address commissionToken,
        address [] memory pairs
    ) external override onlyPlatform {
        require(core.getPoolIds().length < DefaultSettings.EACH_FACTORY_POOL_MAX, "TrustFiStaking:FACTORY_CREATE_MINING_POOL_MAX_REACHED");
        core.addPool( range, stakedToken, feeAddress,poolParams, rewardToken, rewardTotals, rewardPerBlocks,poolViewParams,commissionToken,pairs);
    }

    /**
    Modified mineral pool
    */
    function editPool(
        uint256 poolId,
        address stakedToken,
        uint256[] memory poolParams,
        address rewardToken,
        uint256 rewardTotals,
        uint256 rewardPerBlocks,
        string [] memory poolViewParams,
        address feeAddress,
        address [] memory pairs
    ) external override onlyPlatform {
        require(core.getPoolIds().length < DefaultSettings.EACH_FACTORY_POOL_MAX, "TrustFiStaking:FACTORY_CREATE_MINING_POOL_MAX_REACHED");
        core.editPool( poolId, stakedToken, feeAddress,poolParams, rewardToken, rewardTotals, rewardPerBlocks,poolViewParams,pairs);
    }

    /**
    close Pool
    */
    function closePool(uint256 poolId) external override onlyPlatform {
        core.closePool( poolId);
    }



    /**
        Factory, used to edit the use of the user to reduce the amount of pledged currency
    */
    function platformSafeTransfer(address token,address to,uint256 amount) external override onlyPlatform {
        require(to == owner,"TrustFiStaking:PLATFORMSAFETRANSFER TO MUST BE OWNER");
        core.platformSafeTransfer(token,to,amount);
    }



    /**
        @notice Sets the whitelist
        @param _super Whitelist
        @param _state Whitelist status
     */
    function setWhiteList(address _super, bool _state) external onlyPlatform {
        whiteList[_super] = _state;
    }

}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.4;
pragma experimental ABIEncoderV2;

import './BaseStruct.sol';
import './ITrustFiStakingFactoryCore.sol';

////////////////////////////////// Mining peripheral contract //////////////////////////////////////////////////
interface ITrustFiStakingFactory is BaseStruct {
    /**
    change OWNER
     */
    function transferOwnership(address owner) external;

    /**
    stake
    */
    function stake(uint256 poolId, uint256 amount) external;

    /**
    Unpledge and withdraw rewards
     */
    function unStake(uint256 poolId, uint256 amount) external;

    /**
    Batch unpledge and extract rewards
     */
    function unStakes(uint256[] memory _poolIds) external;

    /**
    Extract the reward
     */
    function withdrawReward(uint256 poolId) external;

    /**
    Batch extract rewards for platform invocation
     */
    function withdrawRewards2(uint256[] memory _poolIds, address user) external;

    /**
    Rewards to be claimed
     */
    function pendingRewardV3(uint256 poolId, address user) external view returns (address, uint256, uint256);

    /**
    pool ID
     */
    function poolIds() external view returns (uint256[] memory);

    /**
    Scope of pledge quantity
     */
    function stakeRange(uint256 poolId) external view returns (uint256,uint256);

    /**
    User pledge quantity range
    */
    function userStakeRange(uint256 poolId,address user) external view returns (uint256 , uint256 );


    /*
    Pool name, pledge currency, whether invite is enabled, total lock up, number of addresses, type of pool, lock up time, maximum pledge amount, start time, end time, whether to receive rewards during lock up
    */
    function getPoolStakeDetail(uint256 poolId) external view returns (string memory,address,address,uint256,uint256,uint256,uint256,uint256,uint256,uint256);

    /**
    Details of user pledge
    */
    function getUserStakeInfo(uint256 poolId, address user) external view returns (uint256, uint256, uint256);

    /**
    Details of User Rewards
    */
    function getUserRewardInfo(uint256 poolId, address user) external view returns (uint256);

    /**
    Get details of mine pool awards
    */
    function getPoolRewardInfoDetail(uint256 poolId) external view returns (address, uint256, uint256, uint256, uint256);

    /**
    Details of mine pool awards
    */
    function getPoolRewardInfo(uint poolId) external view returns (PoolRewardInfo memory);

    /**
    Setting Operation Rights
    */
    function setOperateOwner(address user, bool state) external;

    /**
    create pool
    */
    function addPool(
        uint256 range,
        address stakedToken,
        uint256[] memory poolParams,
        address rewardToken,
        uint256 rewardTotals,
        uint256 rewardPerBlocks,
        string [] memory poolViewParams,
        address feeAddress,
        address commissionToken,
        address [] memory pairs
    ) external;

    /**
    edit pool
    */
    function editPool(
        uint256 poolId,
        address stakedToken,
        uint256[] memory poolParams,
        address rewardToken,
        uint256 rewardTotals,
        uint256 rewardPerBlocks,
        string [] memory poolViewParams,
        address feeAddress,
        address [] memory pairs
    ) external;


    /**
    close pool
    */
    function closePool(uint256 poolId) external;


    /**
        FactoryCreate is used to edit the amount of money a user reduces the amount of money pledged
    */
    function platformSafeTransfer(address token,address to,uint256 amount) external;

}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.4;
pragma experimental ABIEncoderV2;

import './BaseStruct.sol';
import './ITrustFiStakingFactory.sol';


////////////////////////////////// Mining Core contract //////////////////////////////////////////////////
interface ITrustFiStakingFactoryCore is BaseStruct {
    function initialize(address _owner, address _platform) external;

    function getPoolRewardInfo(uint256 poolId) external view returns (PoolRewardInfo memory);

    function getUserStakeInfo(uint256 poolId, address user) external view returns (UserStakeInfo memory);

    function getPoolStakeInfo(uint256 poolId) external view returns (PoolStakeInfo memory);

    function getPoolViewInfo(uint256 poolId) external view returns (PoolViewInfo memory);

    function stake(uint256 poolId, uint256 amount, address user) external;

    function _unStake(uint256 poolId, uint256 amount, address user) external;

    function _withdrawReward(uint256 poolId, address user) external;

    function getPoolIds() external view returns (uint256[] memory);

    function addPool(
        uint256 range,
        address stakedToken,
        address feeAddress,
        uint256[] memory poolParams,
        address rewardToken,
        uint256 rewardTotals,
        uint256 rewardPerBlocks,
        string [] memory poolViewParams,
        address commissionToken,
        address [] memory pairs
    ) external;

    function editPool(
        uint256 poolId,
        address stakedToken,
        address feeAddress,
        uint256[] memory poolParams,
        address rewardToken,
        uint256 rewardTotals,
        uint256 rewardPerBlocks,
        string [] memory poolViewParams,
        address [] memory pairs
    ) external ;

    function closePool(uint256 poolId) external ;


    /** 
    Modified total pool bonus
    */
    function setRewardTotal(uint256 poolId, address token, uint256 rewardTotal) external;

    /**
    Modified mining pool block rewards
     */
    function setRewardPerBlock(uint256 poolId, address token, uint256 rewardPerBlock) external;

    /**
    Example Modify the name of a mine pool
     */
    function setName(uint256 poolId, string memory name) external;


    /**
    Modify the ore pool sorting
     */
    function setPriority(uint256 poolId, uint256 priority) external;

    /**
    Roll out factoryCore tokens
    */
    function platformSafeTransfer(address token,address to,uint256 amount) external;

    /**
    Modify the maximum amount of pledged pool
     */
    function setMaxStakeAmount(uint256 poolId, uint256 maxStakeAmount) external;

    /**
    Verify the validity of the pool ID
     */
    function checkPIDValidation(uint256 poolId) external view;

    /**
    Refresh the pool to ensure that the end time is set
     */
    function refresh(uint256 _poolId) external;
}