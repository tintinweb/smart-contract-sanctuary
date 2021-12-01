// SPDX-License-Identifier: MIT
pragma solidity >0.7.5;
pragma experimental ABIEncoderV2;

import "./interfaces/iL2LiquidityPool.sol";
import "../libraries/CrossDomainEnabledFast.sol";

/* External Imports */
import '@openzeppelin/contracts/utils/math/SafeMath.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";

/* External Imports */
import "@eth-optimism/contracts/contracts/L1/messaging/L1StandardBridge.sol";

/**
 * @dev An L1 LiquidityPool implementation
 */
contract L1LiquidityPool is CrossDomainEnabledFast, ReentrancyGuardUpgradeable, PausableUpgradeable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    /**************
     *   Struct   *
     **************/
    // Info of each user.
    struct UserInfo {
        uint256 amount; // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
        uint256 pendingReward; // Pending reward
        //
        // We do some fancy math here. Basically, any point in time, the amount of rewards
        // entitled to a user but is pending to be distributed is:
        //
        //   Update Reward Per Share:
        //   accUserRewardPerShare = accUserRewardPerShare + (accUserReward - lastAccUserReward) / userDepositAmount
        //
        //  LP Provider:
        //      Deposit:
        //          Case 1 (new user):
        //              Update Reward Per Share();
        //              Calculate user.rewardDebt = amount * accUserRewardPerShare;
        //          Case 2 (user who has already deposited add more funds):
        //              Update Reward Per Share();
        //              Calculate user.pendingReward = amount * accUserRewardPerShare - user.rewardDebt;
        //              Calculate user.rewardDebt = (amount + new_amount) * accUserRewardPerShare;
        //
        //      Withdraw
        //          Update Reward Per Share();
        //          Calculate user.pendingReward = amount * accUserRewardPerShare - user.rewardDebt;
        //          Calculate user.rewardDebt = (amount - withdraw_amount) * accUserRewardPerShare;
    }
    // Info of each pool.
    struct PoolInfo {
        address l1TokenAddress; // Address of token contract.
        address l2TokenAddress; // Address of toekn contract.

        // balance
        uint256 userDepositAmount; // user deposit amount;

        // user rewards
        uint256 lastAccUserReward; // Last accumulated user reward
        uint256 accUserReward; // Accumulated user reward.
        uint256 accUserRewardPerShare; // Accumulated user rewards per share, times 1e12. See below.

        // owner rewards
        uint256 accOwnerReward; // Accumulated owner reward.

        // start time -- used to calculate APR
        uint256 startTime;
    }

    /*************
     * Variables *
     *************/

    // mapping L1 and L2 token address to poolInfo
    mapping(address => PoolInfo) public poolInfo;
    // Info of each user that stakes tokens.
    mapping(address => mapping(address => UserInfo)) public userInfo;

    address public owner;
    address public L2LiquidityPoolAddress;
    uint256 public userRewardMinFeeRate;
    uint256 public ownerRewardFeeRate;
    // Default gas value which can be overridden if more complex logic runs on L2.
    uint32 public SETTLEMENT_L2_GAS;
    uint256 public SAFE_GAS_STIPEND;
    // cdm address
    address public l1CrossDomainMessenger;
    // L1StandardBridge address
    address payable public L1StandardBridgeAddress;
    uint256 public userRewardMaxFeeRate;

    /********************
     *       Events     *
     ********************/

    event AddLiquidity(
        address sender,
        uint256 amount,
        address tokenAddress
    );

    event OwnerRecoverFee(
        address sender,
        address receiver,
        uint256 amount,
        address tokenAddress
    );

    event ClientDepositL1(
        address sender,
        uint256 receivedAmount,
        address tokenAddress
    );

    event ClientPayL1(
        address sender,
        uint256 amount,
        uint256 userRewardFee,
        uint256 ownerRewardFee,
        uint256 totalFee,
        address tokenAddress
    );

    event ClientPayL1Settlement(
        address sender,
        uint256 amount,
        uint256 userRewardFee,
        uint256 ownerRewardFee,
        uint256 totalFee,
        address tokenAddress
    );

    event WithdrawLiquidity(
        address sender,
        address receiver,
        uint256 amount,
        address tokenAddress
    );

    event WithdrawReward(
        address sender,
        address receiver,
        uint256 amount,
        address tokenAddress
    );

    event RebalanceLP(
        uint256 amount,
        address tokenAddress
    );

    /********************
     *    Constructor   *
     ********************/

    constructor()
        CrossDomainEnabledFast(address(0), address(0))
    {}

    /**********************
     * Function Modifiers *
     **********************/

    modifier onlyOwner() {
        require(msg.sender == owner || owner == address(0), 'Caller is not the owner');
        _;
    }

    modifier onlyNotInitialized() {
        require(address(L2LiquidityPoolAddress) == address(0), "Contract has been initialized");
        _;
    }

    modifier onlyInitialized() {
        require(address(L2LiquidityPoolAddress) != address(0), "Contract has not yet been initialized");
        _;
    }

    modifier onlyL1StandardBridge() {
        require(address(L1StandardBridgeAddress) == msg.sender, "Can't receive ETH");
        _;
    }

    /********************
     * Fall back Functions *
     ********************/
    receive()
        external
        payable
        onlyL1StandardBridge()
    {}

    /********************
     * Public Functions *
     ********************/

    /**
     * @dev transfer ownership
     *
     * @param _newOwner new owner of this contract
     */
    function transferOwnership(
        address _newOwner
    )
        public
        onlyOwner()
    {
        owner = _newOwner;
    }

    /**
     * @dev Initialize this contract.
     *
     * @param _l1CrossDomainMessenger L1 Messenger address being used for sending the cross-chain message.
     * @param _l1CrossDomainMessengerFast L1 Messenger address being used for relaying cross-chain messages quickly.
     * @param _L2LiquidityPoolAddress Address of the corresponding L2 LP deployed to the L2 chain
     * @param _L1StandardBridgeAddress Address of L1 StandardBridge
     */
    function initialize(
        address _l1CrossDomainMessenger,
        address _l1CrossDomainMessengerFast,
        address _L2LiquidityPoolAddress,
        address payable _L1StandardBridgeAddress
    )
        public
        onlyOwner()
        onlyNotInitialized()
        initializer()
    {
        require(_l1CrossDomainMessenger != address(0) && _l1CrossDomainMessengerFast != address(0) && _L2LiquidityPoolAddress != address(0), "zero address not allowed");
        senderMessenger = _l1CrossDomainMessenger;
        relayerMessenger = _l1CrossDomainMessengerFast;
        L2LiquidityPoolAddress = _L2LiquidityPoolAddress;
        L1StandardBridgeAddress = _L1StandardBridgeAddress;
        owner = msg.sender;
        _configureFee(5, 50, 0);
        configureGas(1400000, 2300);

        __Context_init_unchained();
        __Pausable_init_unchained();
        __ReentrancyGuard_init_unchained();

    }

    function _configureFee(
        uint256 _userRewardMinFeeRate,
        uint256 _userRewardMaxFeeRate,
        uint256 _ownerRewardFeeRate
    )
        internal
    {
        userRewardMinFeeRate = _userRewardMinFeeRate;
        userRewardMaxFeeRate = _userRewardMaxFeeRate;
        ownerRewardFeeRate = _ownerRewardFeeRate;
    }

    /**
     * @dev Configure gas.
     *
     * @param _l2GasFee default finalized deposit L2 Gas
     * @param _safeGas safe gas stipened
     */
    function configureGas(
        uint32 _l2GasFee,
        uint256 _safeGas
    )
        public
        onlyOwner()
        onlyInitialized()
    {
        SETTLEMENT_L2_GAS = _l2GasFee;
        SAFE_GAS_STIPEND = _safeGas;
    }

    /**
     * @dev Return user reward fee rate.
     *
     * @param _l1TokenAddress L1 token address
     */
    function getUserRewardFeeRate(
        address _l1TokenAddress
    )
        public
        view
        onlyInitialized()
        returns (uint256 userRewardFeeRate)
    {
        PoolInfo storage pool = poolInfo[_l1TokenAddress];
        uint256 poolLiquidity = pool.userDepositAmount;
        uint256 poolBalance;
        if (_l1TokenAddress == address(0)) {
            poolBalance = address(this).balance;
        } else {
            poolBalance = IERC20(_l1TokenAddress).balanceOf(address(this));
        }
        if (poolBalance == 0) {
            return userRewardMaxFeeRate;
        } else {
            uint256 poolRewardRate = userRewardMinFeeRate * poolLiquidity / poolBalance;
            if (userRewardMinFeeRate > poolRewardRate) {
                return userRewardMinFeeRate;
            } else if (userRewardMaxFeeRate < poolRewardRate) {
                return userRewardMaxFeeRate;
            }
            return poolRewardRate;
        }
    }

    /***
     * @dev Add the new token pair to the pool
     * DO NOT add the same LP token more than once. Rewards will be messed up if you do.
     *
     * @param _l1TokenAddress
     * @param _l2TokenAddress
     *
     */
    function registerPool(
        address _l1TokenAddress,
        address _l2TokenAddress
    )
        public
        onlyOwner()
    {
        require(_l1TokenAddress != _l2TokenAddress, "l1 and l2 token addresses cannot be same");
        // use with caution, can register only once
        PoolInfo storage pool = poolInfo[_l1TokenAddress];
        // l2 token address equal to zero, then pair is not registered.
        require(pool.l2TokenAddress == address(0), "Token Address Already Registered");
        poolInfo[_l1TokenAddress] =
            PoolInfo({
                l1TokenAddress: _l1TokenAddress,
                l2TokenAddress: _l2TokenAddress,
                userDepositAmount: 0,
                lastAccUserReward: 0,
                accUserReward: 0,
                accUserRewardPerShare: 0,
                accOwnerReward: 0,
                startTime: block.timestamp
            });
    }

    /**
     * Update the user reward per share
     * @param _tokenAddress Address of the target token.
     */
    function updateUserRewardPerShare(
        address _tokenAddress
    )
        public
    {
        PoolInfo storage pool = poolInfo[_tokenAddress];
        if (pool.lastAccUserReward < pool.accUserReward) {
            uint256 accUserRewardDiff = (pool.accUserReward.sub(pool.lastAccUserReward));
            if (pool.userDepositAmount != 0) {
                pool.accUserRewardPerShare = pool.accUserRewardPerShare.add(
                    accUserRewardDiff.mul(1e12).div(pool.userDepositAmount)
                );
            }
            pool.lastAccUserReward = pool.accUserReward;
        }
    }

    /**
     * Liquididity providers add liquidity
     * @param _amount liquidity amount that users want to deposit.
     * @param _tokenAddress address of the liquidity token.
     */
     function addLiquidity(
        uint256 _amount,
        address _tokenAddress
    )
        external
        payable
        nonReentrant
        whenNotPaused
    {
        require(msg.value != 0 || _tokenAddress != address(0), "Amount Incorrect");
        // check whether user sends ETH or ERC20
        if (msg.value != 0) {
            // override the _amount and token address
            _amount = msg.value;
            _tokenAddress = address(0);
        }

        PoolInfo storage pool = poolInfo[_tokenAddress];
        UserInfo storage user = userInfo[_tokenAddress][msg.sender];

        require(pool.l2TokenAddress != address(0), "Token Address Not Registered");

        // Update accUserRewardPerShare
        updateUserRewardPerShare(_tokenAddress);

        // if the user has already deposited token, we move the rewards to
        // pendingReward and update the reward debet.
        if (user.amount > 0) {
            user.pendingReward = user.pendingReward.add(
                user.amount.mul(pool.accUserRewardPerShare).div(1e12).sub(user.rewardDebt)
            );
            user.rewardDebt = (user.amount.add(_amount)).mul(pool.accUserRewardPerShare).div(1e12);
        } else {
            user.rewardDebt = _amount.mul(pool.accUserRewardPerShare).div(1e12);
        }

        // transfer funds if users deposit ERC20
        if (_tokenAddress != address(0)) {
            IERC20(_tokenAddress).safeTransferFrom(msg.sender, address(this), _amount);
        }

        // update amounts
        user.amount = user.amount.add(_amount);
        pool.userDepositAmount = pool.userDepositAmount.add(_amount);

        emit AddLiquidity(
            msg.sender,
            _amount,
            _tokenAddress
        );
    }

    /**
     * Client deposit ERC20 from their account to this contract, which then releases funds on the L2 side
     * @param _amount amount that client wants to transfer.
     * @param _tokenAddress L2 token address
     */
    function clientDepositL1(
        uint256 _amount,
        address _tokenAddress
    )
        external
        payable
        whenNotPaused
    {
        require(msg.value != 0 || _tokenAddress != address(0), "Amount Incorrect");
        // check whether user sends ETH or ERC20
        if (msg.value != 0) {
            // override the _amount and token address
            _amount = msg.value;
            _tokenAddress = address(0);
        }

        PoolInfo storage pool = poolInfo[_tokenAddress];

        require(pool.l2TokenAddress != address(0), "Token Address Not Registered");

        // transfer funds if users deposit ERC20
        if (_tokenAddress != address(0)) {
            IERC20(_tokenAddress).safeTransferFrom(msg.sender, address(this), _amount);
        }

        // Construct calldata for L1LiquidityPool.depositToFinalize(_to, receivedAmount)
        bytes memory data = abi.encodeWithSelector(
            iL2LiquidityPool.clientPayL2.selector,
            msg.sender,
            _amount,
            pool.l2TokenAddress
        );

        // Send calldata into L1
        sendCrossDomainMessage(
            address(L2LiquidityPoolAddress),
            // extra gas for complex l2 logic
            SETTLEMENT_L2_GAS,
            data
        );

        emit ClientDepositL1(
            msg.sender,
            _amount,
            _tokenAddress
        );
    }

    /**
     * Users withdraw token from LP
     * @param _amount amount to withdraw
     * @param _tokenAddress L1 token address
     * @param _to receiver to get the funds
     */
    function withdrawLiquidity(
        uint256 _amount,
        address _tokenAddress,
        address payable _to
    )
        external
        whenNotPaused
    {
        PoolInfo storage pool = poolInfo[_tokenAddress];
        UserInfo storage user = userInfo[_tokenAddress][msg.sender];

        require(pool.l2TokenAddress != address(0), "Token Address Not Registered");
        require(user.amount >= _amount, "Withdraw Error");

        // Update accUserRewardPerShare
        updateUserRewardPerShare(_tokenAddress);

        // calculate all the rewards and set it as pending rewards
        user.pendingReward = user.pendingReward.add(
            user.amount.mul(pool.accUserRewardPerShare).div(1e12).sub(user.rewardDebt)
        );
        // Update the user data
        user.amount = user.amount.sub(_amount);
        // update reward debt
        user.rewardDebt = user.amount.mul(pool.accUserRewardPerShare).div(1e12);
        // update total user deposit amount
        pool.userDepositAmount = pool.userDepositAmount.sub(_amount);

        if (_tokenAddress != address(0)) {
            IERC20(_tokenAddress).safeTransfer(_to, _amount);
        } else {
            (bool sent,) = _to.call{gas: SAFE_GAS_STIPEND, value: _amount}("");
            require(sent, "Failed to send ETH");
        }

        emit WithdrawLiquidity(
            msg.sender,
            _to,
            _amount,
            _tokenAddress
        );
    }

    /**
     * owner recovers fee from ERC20
     * @param _amount amount that owner wants to recover.
     * @param _tokenAddress L1 token address
     * @param _to receiver to get the fee.
     */
    function ownerRecoverFee(
        uint256 _amount,
        address _tokenAddress,
        address _to
    )
        external
        onlyOwner()
    {
        PoolInfo storage pool = poolInfo[_tokenAddress];

        require(pool.l2TokenAddress != address(0), "Token Address Not Registered");
        require(pool.accOwnerReward >= _amount, "Owner Reward Withdraw Error");

        pool.accOwnerReward = pool.accOwnerReward.sub(_amount);

        if (_tokenAddress != address(0)) {
            IERC20(_tokenAddress).safeTransfer(_to, _amount);
        } else {
            (bool sent,) = _to.call{gas: SAFE_GAS_STIPEND, value: _amount}("");
            require(sent, "Failed to send Ether");
        }

        emit OwnerRecoverFee(
            msg.sender,
            _to,
            _amount,
            _tokenAddress
        );
    }

    /**
     * withdraw reward from ERC20
     * @param _amount reward amount that liquidity providers want to withdraw
     * @param _tokenAddress L1 token address
     * @param _to receiver to get the reward
     */
    function withdrawReward(
        uint256 _amount,
        address _tokenAddress,
        address _to
    )
        external
        whenNotPaused
    {
        PoolInfo storage pool = poolInfo[_tokenAddress];
        UserInfo storage user = userInfo[_tokenAddress][msg.sender];

        require(pool.l2TokenAddress != address(0), "Token Address Not Registered");

        uint256 pendingReward = user.pendingReward.add(
            user.amount.mul(pool.accUserRewardPerShare).div(1e12).sub(user.rewardDebt)
        );

        require(pendingReward >= _amount, "Withdraw Reward Error");

        user.pendingReward = pendingReward.sub(_amount);
        user.rewardDebt = user.amount.mul(pool.accUserRewardPerShare).div(1e12);

        if (_tokenAddress != address(0)) {
            IERC20(_tokenAddress).safeTransfer(_to, _amount);
        } else {
            (bool sent,) = _to.call{gas: SAFE_GAS_STIPEND, value: _amount}("");
            require(sent, "Failed to send Ether");
        }

        emit WithdrawReward(
            msg.sender,
            _to,
            _amount,
            _tokenAddress
        );
    }

    /*
     * Rebalance LPs
     * @param _amount token amount that we want to move from L1 to L2
     * @param _tokenAddress L1 token address
     */
    function rebalanceLP(
        uint256 _amount,
        address _tokenAddress
    )
        external
        onlyOwner()
        whenNotPaused()
    {
        require(_amount != 0, "Amount Incorrect");

        PoolInfo storage pool = poolInfo[_tokenAddress];

        require(L2LiquidityPoolAddress != address(0), "L2 Liquidity Pool Not Registered");
        require(pool.l2TokenAddress != address(0), "Token Address Not Registered");

        if (_tokenAddress == address(0)) {
            require(_amount <= address(this).balance, "Failed to Rebalance LP");
            L1StandardBridge(L1StandardBridgeAddress).depositETHTo{value: _amount}(
                L2LiquidityPoolAddress,
                SETTLEMENT_L2_GAS,
                ""
            );
        } else {
            require(_amount <= IERC20(_tokenAddress).balanceOf(address(this)), "Failed to Rebalance LP");
            IERC20(_tokenAddress).safeIncreaseAllowance(L1StandardBridgeAddress, _amount);
            L1StandardBridge(L1StandardBridgeAddress).depositERC20To(
                _tokenAddress,
                pool.l2TokenAddress,
                L2LiquidityPoolAddress,
                _amount,
                SETTLEMENT_L2_GAS,
                ""
            );
        }
        emit RebalanceLP(
            _amount,
            _tokenAddress
        );
    }

    /**
     * Pause contract
     */
    function pause() external onlyOwner() {
        _pause();
    }

    /**
     * UnPause contract
     */
    function unpause() external onlyOwner() {
        _unpause();
    }

    /*************************
     * Cross-chain Functions *
     *************************/

    /**
     * Move funds from L2 to L1, and pay out from the right liquidity pool
     * part of the contract pause, if only this method needs pausing use pause on CDM_Fast
     * @param _to receiver to get the funds
     * @param _amount amount to to be transferred.
     * @param _tokenAddress L1 token address
     */
    function clientPayL1(
        address payable _to,
        uint256 _amount,
        address _tokenAddress
    )
        external
        onlyFromCrossDomainAccount(address(L2LiquidityPoolAddress))
        whenNotPaused
    {
        bool replyNeeded = false;
        PoolInfo storage pool = poolInfo[_tokenAddress];
        uint256 userRewardFeeRate = getUserRewardFeeRate(_tokenAddress);
        uint256 userRewardFee = (_amount.mul(userRewardFeeRate)).div(1000);
        uint256 ownerRewardFee = (_amount.mul(ownerRewardFeeRate)).div(1000);
        uint256 totalFee = userRewardFee.add(ownerRewardFee);
        uint256 receivedAmount = _amount.sub(totalFee);

        if (_tokenAddress != address(0)) {
            //IERC20(_tokenAddress).safeTransfer(_to, _amount);
            if (receivedAmount > IERC20(_tokenAddress).balanceOf(address(this))) {
                replyNeeded = true;
            } else {
                pool.accUserReward = pool.accUserReward.add(userRewardFee);
                pool.accOwnerReward = pool.accOwnerReward.add(ownerRewardFee);
                IERC20(_tokenAddress).safeTransfer(_to, receivedAmount);
            }
        } else {
            // //this is ETH
            // // balances[address(0)] = balances[address(0)].sub(_amount);
            // //_to.transfer(_amount); UNSAFE
            // (bool sent,) = _to.call{gas: SAFE_GAS_STIPEND, value: _amount}("");
            // require(sent, "Failed to send Ether");
            if (receivedAmount > address(this).balance) {
                 replyNeeded = true;
             } else {
                pool.accUserReward = pool.accUserReward.add(userRewardFee);
                pool.accOwnerReward = pool.accOwnerReward.add(ownerRewardFee);
                 //this is ETH
                 // balances[address(0)] = balances[address(0)].sub(_amount);
                 //_to.transfer(_amount); UNSAFE
                 (bool sent,) = _to.call{gas: SAFE_GAS_STIPEND, value: receivedAmount}("");
                 require(sent, "Failed to send ETH");
             }
         }

         if (replyNeeded) {
             // send cross domain message
             bytes memory data = abi.encodeWithSelector(
             iL2LiquidityPool.clientPayL2Settlement.selector,
             _to,
             _amount,
             pool.l2TokenAddress
             );

             sendCrossDomainMessage(
                 address(L2LiquidityPoolAddress),
                 SETTLEMENT_L2_GAS,
                 data
             );
         } else {
             emit ClientPayL1(
             _to,
             receivedAmount,
             userRewardFee,
             ownerRewardFee,
             totalFee,
             _tokenAddress
             );
         }
    }

    /**
     * Settlement pay when there's not enough funds on the other side
     * part of the contract pause, if only this method needs pausing use pause on CDM_Fast
     * @param _to receiver to get the funds
     * @param _amount amount to to be transferred.
     * @param _tokenAddress L1 token address
     */
    function clientPayL1Settlement(
        address payable _to,
        uint256 _amount,
        address _tokenAddress
    )
        external
        onlyFromCrossDomainAccount(address(L2LiquidityPoolAddress))
        whenNotPaused
    {
        PoolInfo storage pool = poolInfo[_tokenAddress];
        uint256 userRewardFeeRate = getUserRewardFeeRate(_tokenAddress);
        uint256 userRewardFee = (_amount.mul(userRewardFeeRate)).div(1000);
        uint256 ownerRewardFee = (_amount.mul(ownerRewardFeeRate)).div(1000);
        uint256 totalFee = userRewardFee.add(ownerRewardFee);
        uint256 receivedAmount = _amount.sub(totalFee);

        pool.accUserReward = pool.accUserReward.add(userRewardFee);
        pool.accOwnerReward = pool.accOwnerReward.add(ownerRewardFee);

        if (_tokenAddress != address(0)) {
            IERC20(_tokenAddress).safeTransfer(_to, receivedAmount);
        } else {
            //this is ETH
            // balances[address(0)] = balances[address(0)].sub(_amount);
            //_to.transfer(_amount); UNSAFE
            (bool sent,) = _to.call{gas: SAFE_GAS_STIPEND, value: receivedAmount}("");
            require(sent, "Failed to send Ether");
        }

        emit ClientPayL1Settlement(
        _to,
        receivedAmount,
        userRewardFee,
        ownerRewardFee,
        totalFee,
        _tokenAddress
        );
    }

    /**
     * @dev Configure fee of this contract. called from L2
     *
     * @param _userRewardMinFeeRate minimum fee rate that users get
     * @param _userRewardMaxFeeRate maximum fee rate that users get
     * @param _ownerRewardFeeRate fee rate that contract owner gets
     */
    function configureFee(
        uint256 _userRewardMinFeeRate,
        uint256 _userRewardMaxFeeRate,
        uint256 _ownerRewardFeeRate
    )
        external
        onlyFromCrossDomainAccount(address(L2LiquidityPoolAddress))
        onlyInitialized()
    {
        require(_userRewardMinFeeRate <= _userRewardMaxFeeRate, "Invalud user reward fee");
        _configureFee(_userRewardMinFeeRate, _userRewardMaxFeeRate,_ownerRewardFeeRate);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >0.7.5;
pragma experimental ABIEncoderV2;

/**
 * @title iL2LiquidityPool
 */
interface iL2LiquidityPool {

    /********************
     *       Events     *
     ********************/

    event AddLiquidity(
        address sender,
        uint256 amount,
        address tokenAddress
    );

    event OwnerRecoverFee(
        address sender,
        address receiver,
        uint256 amount,
        address tokenAddress
    );

    event ClientDepositL2(
        address sender,
        uint256 receivedAmount,
        address tokenAddress
    );

    event ClientPayL2(
        address sender,
        uint256 amount,
        uint256 userRewardFee,
        uint256 ownerRewardFee,
        uint256 totalFee,
        address tokenAddress
    );

    event ClientPayL2Settlement(
        address sender,
        uint256 amount,
        uint256 userRewardFee,
        uint256 ownerRewardFee,
        uint256 totalFee,
        address tokenAddress
    );

    event WithdrawLiquidity(
        address sender,
        address receiver,
        uint256 amount,
        address tokenAddress
    );

    event WithdrawReward(
        address sender,
        address receiver,
        uint256 amount,
        address tokenAddress
    );

    /*************************
     * Cross-chain Functions *
     *************************/

    function clientPayL2(
        address payable _to,
        uint256 _amount,
        address _tokenAddress
    )
        external;

    function clientPayL2Settlement(
        address payable _to,
        uint256 _amount,
        address _tokenAddress
    )
        external;
}

// SPDX-License-Identifier: MIT
pragma solidity >0.7.5;
/* Interface Imports */
import { ICrossDomainMessenger } from "@eth-optimism/contracts/contracts/libraries/bridge/ICrossDomainMessenger.sol";

/**
 * @title CrossDomainEnabledFast
 * @dev Helper contract for contracts performing cross-domain communications
 *
 * Compiler used: defined by inheriting contract
 * Runtime target: defined by inheriting contract
 */
contract CrossDomainEnabledFast {

    // Messenger contract used to send and receive messages from the other domain.
    address public senderMessenger;
    address public relayerMessenger;

    /***************
     * Constructor *
     ***************/
    constructor(
        address _senderMessenger,
        address _relayerMessenger
    ) {
        senderMessenger = _senderMessenger;
        relayerMessenger = _relayerMessenger;
    }

    /**********************
     * Function Modifiers *
     **********************/

    /**
     * @notice Enforces that the modified function is only callable by a specific cross-domain account.
     * @param _sourceDomainAccount The only account on the originating domain which is authenticated to call this function.
     */
    modifier onlyFromCrossDomainAccount(
        address _sourceDomainAccount
    ) {
        require(
            msg.sender == address(getCrossDomainRelayerMessenger()),
            "XCHAIN: messenger contract unauthenticated"
        );

        require(
            getCrossDomainRelayerMessenger().xDomainMessageSender() == _sourceDomainAccount,
            "XCHAIN: wrong sender of cross-domain message"
        );

        _;
    }

    /**********************
     * Internal Functions *
     **********************/

    /**
     * @notice Gets the messenger, usually from storage.  This function is exposed in case a child contract needs to override.
     * @return The address of the cross-domain messenger contract which should be used.
     */
    function getCrossDomainSenderMessenger()
        internal
        virtual
        returns(
            ICrossDomainMessenger
        )
    {
        return ICrossDomainMessenger(senderMessenger);
    }

    /**
     * @notice Gets the messenger, usually from storage.  This function is exposed in case a child contract needs to override.
     * @return The address of the cross-domain messenger contract which should be used.
     */
    function getCrossDomainRelayerMessenger()
        internal
        virtual
        returns(
            ICrossDomainMessenger
        )
    {
        return ICrossDomainMessenger(relayerMessenger);
    }

    /**
     * @notice Sends a message to an account on another domain
     * @param _crossDomainTarget The intended recipient on the destination domain
     * @param _data The data to send to the target (usually calldata to a function with `onlyFromCrossDomainAccount()`)
     * @param _gasLimit The gasLimit for the receipt of the message on the target domain.
     */
    function sendCrossDomainMessage(
        address _crossDomainTarget,
        uint32 _gasLimit,
        bytes memory _data
    ) internal {
        getCrossDomainSenderMessenger().sendMessage(_crossDomainTarget, _data, _gasLimit);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
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
        return a + b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

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
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
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
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuardUpgradeable is Initializable {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    function __ReentrancyGuard_init() internal initializer {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal initializer {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    function __Pausable_init() internal initializer {
        __Context_init_unchained();
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal initializer {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/* Interface Imports */
import {IL1StandardBridge} from './IL1StandardBridge.sol';
import {IL1ERC20Bridge} from './IL1ERC20Bridge.sol';
import {IL2ERC20Bridge} from '../../L2/messaging/IL2ERC20Bridge.sol';
import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';

/* Library Imports */
import {CrossDomainEnabled} from '../../libraries/bridge/CrossDomainEnabled.sol';
import {Lib_PredeployAddresses} from '../../libraries/constants/Lib_PredeployAddresses.sol';
import {Address} from '@openzeppelin/contracts/utils/Address.sol';
import {SafeERC20} from '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';

/**
 * @title L1StandardBridge
 * @dev The L1 ETH and ERC20 Bridge is a contract which stores deposited L1 funds and standard
 * tokens that are in use on L2. It synchronizes a corresponding L2 Bridge, informing it of deposits
 * and listening to it for newly finalized withdrawals.
 *
 * Runtime target: EVM
 */
contract L1StandardBridge is IL1StandardBridge, CrossDomainEnabled {
  using SafeERC20 for IERC20;

  /********************************
   * External Contract References *
   ********************************/

  address public l2TokenBridge;

  // Maps L1 token to L2 token to balance of the L1 token deposited
  mapping(address => mapping(address => uint256)) public deposits;

  /***************
   * Constructor *
   ***************/

  // This contract lives behind a proxy, so the constructor parameters will go unused.
  constructor() CrossDomainEnabled(address(0)) {}

  /******************
   * Initialization *
   ******************/

  /**
   * @param _l1messenger L1 Messenger address being used for cross-chain communications.
   * @param _l2TokenBridge L2 standard bridge address.
   */
  function initialize(address _l1messenger, address _l2TokenBridge) public {
    require(messenger == address(0), 'Contract has already been initialized.');
    messenger = _l1messenger;
    l2TokenBridge = _l2TokenBridge;
  }

  /**************
   * Depositing *
   **************/

  /** @dev Modifier requiring sender to be EOA.  This check could be bypassed by a malicious
   *  contract via initcode, but it takes care of the user error we want to avoid.
   */
  modifier onlyEOA() {
    // Used to stop deposits from contracts (avoid accidentally lost tokens)
    require(!Address.isContract(msg.sender), 'Account not EOA');
    _;
  }

  /**
   * @dev This function can be called with no data
   * to deposit an amount of ETH to the caller's balance on L2.
   * Since the receive function doesn't take data, a conservative
   * default amount is forwarded to L2.
   */
  receive() external payable onlyEOA {
    _initiateETHDeposit(msg.sender, msg.sender, 1_300_000, bytes(''));
  }

  /**
   * @inheritdoc IL1StandardBridge
   */
  function depositETH(uint32 _l2Gas, bytes calldata _data)
    external
    payable
    onlyEOA
  {
    _initiateETHDeposit(msg.sender, msg.sender, _l2Gas, _data);
  }

  /**
   * @inheritdoc IL1StandardBridge
   */
  function depositETHTo(
    address _to,
    uint32 _l2Gas,
    bytes calldata _data
  ) external payable {
    _initiateETHDeposit(msg.sender, _to, _l2Gas, _data);
  }

  /**
   * @dev Performs the logic for deposits by storing the ETH and informing the L2 ETH Gateway of
   * the deposit.
   * @param _from Account to pull the deposit from on L1.
   * @param _to Account to give the deposit to on L2.
   * @param _l2Gas Gas limit required to complete the deposit on L2.
   * @param _data Optional data to forward to L2. This data is provided
   *        solely as a convenience for external contracts. Aside from enforcing a maximum
   *        length, these contracts provide no guarantees about its content.
   */
  function _initiateETHDeposit(
    address _from,
    address _to,
    uint32 _l2Gas,
    bytes memory _data
  ) internal {
    // Construct calldata for finalizeDeposit call
    bytes memory message = abi.encodeWithSelector(
      IL2ERC20Bridge.finalizeDeposit.selector,
      address(0),
      Lib_PredeployAddresses.OVM_ETH,
      _from,
      _to,
      msg.value,
      _data
    );

    // Send calldata into L2
    sendCrossDomainMessage(l2TokenBridge, _l2Gas, message);

    emit ETHDepositInitiated(_from, _to, msg.value, _data);
  }

  /**
   * @inheritdoc IL1ERC20Bridge
   */
  function depositERC20(
    address _l1Token,
    address _l2Token,
    uint256 _amount,
    uint32 _l2Gas,
    bytes calldata _data
  ) external virtual onlyEOA {
    _initiateERC20Deposit(
      _l1Token,
      _l2Token,
      msg.sender,
      msg.sender,
      _amount,
      _l2Gas,
      _data
    );
  }

  /**
   * @inheritdoc IL1ERC20Bridge
   */
  function depositERC20To(
    address _l1Token,
    address _l2Token,
    address _to,
    uint256 _amount,
    uint32 _l2Gas,
    bytes calldata _data
  ) external virtual {
    _initiateERC20Deposit(
      _l1Token,
      _l2Token,
      msg.sender,
      _to,
      _amount,
      _l2Gas,
      _data
    );
  }

  /**
   * @dev Performs the logic for deposits by informing the L2 Deposited Token
   * contract of the deposit and calling a handler to lock the L1 funds. (e.g. transferFrom)
   *
   * @param _l1Token Address of the L1 ERC20 we are depositing
   * @param _l2Token Address of the L1 respective L2 ERC20
   * @param _from Account to pull the deposit from on L1
   * @param _to Account to give the deposit to on L2
   * @param _amount Amount of the ERC20 to deposit.
   * @param _l2Gas Gas limit required to complete the deposit on L2.
   * @param _data Optional data to forward to L2. This data is provided
   *        solely as a convenience for external contracts. Aside from enforcing a maximum
   *        length, these contracts provide no guarantees about its content.
   */
  function _initiateERC20Deposit(
    address _l1Token,
    address _l2Token,
    address _from,
    address _to,
    uint256 _amount,
    uint32 _l2Gas,
    bytes calldata _data
  ) internal {
    // When a deposit is initiated on L1, the L1 Bridge transfers the funds to itself for future
    // withdrawals. safeTransferFrom also checks if the contract has code, so this will fail if
    // _from is an EOA or address(0).
    IERC20(_l1Token).safeTransferFrom(_from, address(this), _amount);

    // Construct calldata for _l2Token.finalizeDeposit(_to, _amount)
    bytes memory message = abi.encodeWithSelector(
      IL2ERC20Bridge.finalizeDeposit.selector,
      _l1Token,
      _l2Token,
      _from,
      _to,
      _amount,
      _data
    );

    // Send calldata into L2
    sendCrossDomainMessage(l2TokenBridge, _l2Gas, message);

    deposits[_l1Token][_l2Token] = deposits[_l1Token][_l2Token] + _amount;

    emit ERC20DepositInitiated(_l1Token, _l2Token, _from, _to, _amount, _data);
  }

  /*************************
   * Cross-chain Functions *
   *************************/

  /**
   * @inheritdoc IL1StandardBridge
   */
  function finalizeETHWithdrawal(
    address _from,
    address _to,
    uint256 _amount,
    bytes calldata _data
  ) external onlyFromCrossDomainAccount(l2TokenBridge) {
    (bool success, ) = _to.call{value: _amount}(new bytes(0));
    require(success, 'TransferHelper::safeTransferETH: ETH transfer failed');

    emit ETHWithdrawalFinalized(_from, _to, _amount, _data);
  }

  /**
   * @inheritdoc IL1ERC20Bridge
   */
  function finalizeERC20Withdrawal(
    address _l1Token,
    address _l2Token,
    address _from,
    address _to,
    uint256 _amount,
    bytes calldata _data
  ) external onlyFromCrossDomainAccount(l2TokenBridge) {
    deposits[_l1Token][_l2Token] = deposits[_l1Token][_l2Token] - _amount;

    // When a withdrawal is finalized on L1, the L1 Bridge transfers the funds to the withdrawer
    IERC20(_l1Token).safeTransfer(_to, _amount);

    emit ERC20WithdrawalFinalized(
      _l1Token,
      _l2Token,
      _from,
      _to,
      _amount,
      _data
    );
  }

  /*****************************
   * Temporary - Migrating ETH *
   *****************************/

  /**
   * @dev Adds ETH balance to the account. This is meant to allow for ETH
   * to be migrated from an old gateway to a new gateway.
   * NOTE: This is left for one upgrade only so we are able to receive the migrated ETH from the
   * old contract
   */
  function donateETH() external payable {}
}

// SPDX-License-Identifier: MIT
pragma solidity >0.5.0 <0.9.0;

/**
 * @title ICrossDomainMessenger
 */
interface ICrossDomainMessenger {
  /**********
   * Events *
   **********/

  event SentMessage(
    address indexed target,
    address sender,
    bytes message,
    uint256 messageNonce,
    uint256 gasLimit
  );
  event RelayedMessage(bytes32 indexed msgHash);
  event FailedRelayedMessage(bytes32 indexed msgHash);

  /*************
   * Variables *
   *************/

  function xDomainMessageSender() external view returns (address);

  /********************
   * Public Functions *
   ********************/

  /**
   * Sends a cross domain message to the target messenger.
   * @param _target Target contract address.
   * @param _message Message to send to the target.
   * @param _gasLimit Gas limit for the provided message.
   */
  function sendMessage(
    address _target,
    bytes calldata _message,
    uint32 _gasLimit
  ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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

pragma solidity ^0.8.0;

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
        assembly {
            size := extcodesize(account)
        }
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

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
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
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
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
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
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
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

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

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity >0.5.0 <0.9.0;

import './IL1ERC20Bridge.sol';

/**
 * @title IL1StandardBridge
 */
interface IL1StandardBridge is IL1ERC20Bridge {
  /**********
   * Events *
   **********/
  event ETHDepositInitiated(
    address indexed _from,
    address indexed _to,
    uint256 _amount,
    bytes _data
  );

  event ETHWithdrawalFinalized(
    address indexed _from,
    address indexed _to,
    uint256 _amount,
    bytes _data
  );

  /********************
   * Public Functions *
   ********************/

  /**
   * @dev Deposit an amount of the ETH to the caller's balance on L2.
   * @param _l2Gas Gas limit required to complete the deposit on L2.
   * @param _data Optional data to forward to L2. This data is provided
   *        solely as a convenience for external contracts. Aside from enforcing a maximum
   *        length, these contracts provide no guarantees about its content.
   */
  function depositETH(uint32 _l2Gas, bytes calldata _data) external payable;

  /**
   * @dev Deposit an amount of ETH to a recipient's balance on L2.
   * @param _to L2 address to credit the withdrawal to.
   * @param _l2Gas Gas limit required to complete the deposit on L2.
   * @param _data Optional data to forward to L2. This data is provided
   *        solely as a convenience for external contracts. Aside from enforcing a maximum
   *        length, these contracts provide no guarantees about its content.
   */
  function depositETHTo(
    address _to,
    uint32 _l2Gas,
    bytes calldata _data
  ) external payable;

  /*************************
   * Cross-chain Functions *
   *************************/

  /**
   * @dev Complete a withdrawal from L2 to L1, and credit funds to the recipient's balance of the
   * L1 ETH token. Since only the xDomainMessenger can call this function, it will never be called
   * before the withdrawal is finalized.
   * @param _from L2 address initiating the transfer.
   * @param _to L1 address to credit the withdrawal to.
   * @param _amount Amount of the ERC20 to deposit.
   * @param _data Optional data to forward to L2. This data is provided
   *        solely as a convenience for external contracts. Aside from enforcing a maximum
   *        length, these contracts provide no guarantees about its content.
   */
  function finalizeETHWithdrawal(
    address _from,
    address _to,
    uint256 _amount,
    bytes calldata _data
  ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >0.5.0 <0.9.0;

/**
 * @title IL1ERC20Bridge
 */
interface IL1ERC20Bridge {
  /**********
   * Events *
   **********/

  event ERC20DepositInitiated(
    address indexed _l1Token,
    address indexed _l2Token,
    address indexed _from,
    address _to,
    uint256 _amount,
    bytes _data
  );

  event ERC20WithdrawalFinalized(
    address indexed _l1Token,
    address indexed _l2Token,
    address indexed _from,
    address _to,
    uint256 _amount,
    bytes _data
  );

  /********************
   * Public Functions *
   ********************/

  /**
   * @dev get the address of the corresponding L2 bridge contract.
   * @return Address of the corresponding L2 bridge contract.
   */
  function l2TokenBridge() external returns (address);

  /**
   * @dev deposit an amount of the ERC20 to the caller's balance on L2.
   * @param _l1Token Address of the L1 ERC20 we are depositing
   * @param _l2Token Address of the L1 respective L2 ERC20
   * @param _amount Amount of the ERC20 to deposit
   * @param _l2Gas Gas limit required to complete the deposit on L2.
   * @param _data Optional data to forward to L2. This data is provided
   *        solely as a convenience for external contracts. Aside from enforcing a maximum
   *        length, these contracts provide no guarantees about its content.
   */
  function depositERC20(
    address _l1Token,
    address _l2Token,
    uint256 _amount,
    uint32 _l2Gas,
    bytes calldata _data
  ) external;

  /**
   * @dev deposit an amount of ERC20 to a recipient's balance on L2.
   * @param _l1Token Address of the L1 ERC20 we are depositing
   * @param _l2Token Address of the L1 respective L2 ERC20
   * @param _to L2 address to credit the withdrawal to.
   * @param _amount Amount of the ERC20 to deposit.
   * @param _l2Gas Gas limit required to complete the deposit on L2.
   * @param _data Optional data to forward to L2. This data is provided
   *        solely as a convenience for external contracts. Aside from enforcing a maximum
   *        length, these contracts provide no guarantees about its content.
   */
  function depositERC20To(
    address _l1Token,
    address _l2Token,
    address _to,
    uint256 _amount,
    uint32 _l2Gas,
    bytes calldata _data
  ) external;

  /*************************
   * Cross-chain Functions *
   *************************/

  /**
   * @dev Complete a withdrawal from L2 to L1, and credit funds to the recipient's balance of the
   * L1 ERC20 token.
   * This call will fail if the initialized withdrawal from L2 has not been finalized.
   *
   * @param _l1Token Address of L1 token to finalizeWithdrawal for.
   * @param _l2Token Address of L2 token where withdrawal was initiated.
   * @param _from L2 address initiating the transfer.
   * @param _to L1 address to credit the withdrawal to.
   * @param _amount Amount of the ERC20 to deposit.
   * @param _data Data provided by the sender on L2. This data is provided
   *   solely as a convenience for external contracts. Aside from enforcing a maximum
   *   length, these contracts provide no guarantees about its content.
   */
  function finalizeERC20Withdrawal(
    address _l1Token,
    address _l2Token,
    address _from,
    address _to,
    uint256 _amount,
    bytes calldata _data
  ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/**
 * @title IL2ERC20Bridge
 */
interface IL2ERC20Bridge {
  /**********
   * Events *
   **********/

  event WithdrawalInitiated(
    address indexed _l1Token,
    address indexed _l2Token,
    address indexed _from,
    address _to,
    uint256 _amount,
    bytes _data
  );

  event DepositFinalized(
    address indexed _l1Token,
    address indexed _l2Token,
    address indexed _from,
    address _to,
    uint256 _amount,
    bytes _data
  );

  event DepositFailed(
    address indexed _l1Token,
    address indexed _l2Token,
    address indexed _from,
    address _to,
    uint256 _amount,
    bytes _data
  );

  /********************
   * Public Functions *
   ********************/

  /**
   * @dev get the address of the corresponding L1 bridge contract.
   * @return Address of the corresponding L1 bridge contract.
   */
  function l1TokenBridge() external returns (address);

  /**
   * @dev initiate a withdraw of some tokens to the caller's account on L1
   * @param _l2Token Address of L2 token where withdrawal was initiated.
   * @param _amount Amount of the token to withdraw.
   * param _l1Gas Unused, but included for potential forward compatibility considerations.
   * @param _data Optional data to forward to L1. This data is provided
   *        solely as a convenience for external contracts. Aside from enforcing a maximum
   *        length, these contracts provide no guarantees about its content.
   */
  function withdraw(
    address _l2Token,
    uint256 _amount,
    uint32 _l1Gas,
    bytes calldata _data
  ) external;

  /**
   * @dev initiate a withdraw of some token to a recipient's account on L1.
   * @param _l2Token Address of L2 token where withdrawal is initiated.
   * @param _to L1 adress to credit the withdrawal to.
   * @param _amount Amount of the token to withdraw.
   * param _l1Gas Unused, but included for potential forward compatibility considerations.
   * @param _data Optional data to forward to L1. This data is provided
   *        solely as a convenience for external contracts. Aside from enforcing a maximum
   *        length, these contracts provide no guarantees about its content.
   */
  function withdrawTo(
    address _l2Token,
    address _to,
    uint256 _amount,
    uint32 _l1Gas,
    bytes calldata _data
  ) external;

  /*************************
   * Cross-chain Functions *
   *************************/

  /**
   * @dev Complete a deposit from L1 to L2, and credits funds to the recipient's balance of this
   * L2 token. This call will fail if it did not originate from a corresponding deposit in
   * L1StandardTokenBridge.
   * @param _l1Token Address for the l1 token this is called with
   * @param _l2Token Address for the l2 token this is called with
   * @param _from Account to pull the deposit from on L2.
   * @param _to Address to receive the withdrawal at
   * @param _amount Amount of the token to withdraw
   * @param _data Data provider by the sender on L1. This data is provided
   *        solely as a convenience for external contracts. Aside from enforcing a maximum
   *        length, these contracts provide no guarantees about its content.
   */
  function finalizeDeposit(
    address _l1Token,
    address _l2Token,
    address _from,
    address _to,
    uint256 _amount,
    bytes calldata _data
  ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >0.5.0 <0.9.0;

/* Interface Imports */
import {ICrossDomainMessenger} from './ICrossDomainMessenger.sol';

/**
 * @title CrossDomainEnabled
 * @dev Helper contract for contracts performing cross-domain communications
 *
 * Compiler used: defined by inheriting contract
 * Runtime target: defined by inheriting contract
 */
contract CrossDomainEnabled {
  /*************
   * Variables *
   *************/

  // Messenger contract used to send and recieve messages from the other domain.
  address public messenger;

  /***************
   * Constructor *
   ***************/

  /**
   * @param _messenger Address of the CrossDomainMessenger on the current layer.
   */
  constructor(address _messenger) {
    messenger = _messenger;
  }

  /**********************
   * Function Modifiers *
   **********************/

  /**
   * Enforces that the modified function is only callable by a specific cross-domain account.
   * @param _sourceDomainAccount The only account on the originating domain which is
   *  authenticated to call this function.
   */
  modifier onlyFromCrossDomainAccount(address _sourceDomainAccount) {
    require(
      msg.sender == address(getCrossDomainMessenger()),
      'OVM_XCHAIN: messenger contract unauthenticated'
    );

    require(
      getCrossDomainMessenger().xDomainMessageSender() == _sourceDomainAccount,
      'OVM_XCHAIN: wrong sender of cross-domain message'
    );

    _;
  }

  /**********************
   * Internal Functions *
   **********************/

  /**
   * Gets the messenger, usually from storage. This function is exposed in case a child contract
   * needs to override.
   * @return The address of the cross-domain messenger contract which should be used.
   */
  function getCrossDomainMessenger()
    internal
    virtual
    returns (ICrossDomainMessenger)
  {
    return ICrossDomainMessenger(messenger);
  }

  /**q
   * Sends a message to an account on another domain
   * @param _crossDomainTarget The intended recipient on the destination domain
   * @param _message The data to send to the target (usually calldata to a function with
   *  `onlyFromCrossDomainAccount()`)
   * @param _gasLimit The gasLimit for the receipt of the message on the target domain.
   */
  function sendCrossDomainMessage(
    address _crossDomainTarget,
    uint32 _gasLimit,
    bytes memory _message
  ) internal {
    getCrossDomainMessenger().sendMessage(
      _crossDomainTarget,
      _message,
      _gasLimit
    );
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/**
 * @title Lib_PredeployAddresses
 */
library Lib_PredeployAddresses {
  // solhint-disable max-line-length
  address internal constant L2_TO_L1_MESSAGE_PASSER =
    0x4200000000000000000000000000000000000000;
  address internal constant L1_MESSAGE_SENDER =
    0x4200000000000000000000000000000000000001;
  address internal constant DEPLOYER_WHITELIST =
    0x4200000000000000000000000000000000000002;
  address payable internal constant OVM_ETH =
    payable(0x4200000000000000000000000000000000000006);
  // solhint-disable-next-line max-line-length
  address internal constant L2_CROSS_DOMAIN_MESSENGER =
    0x4200000000000000000000000000000000000007;
  address internal constant LIB_ADDRESS_MANAGER =
    0x4200000000000000000000000000000000000008;
  address internal constant PROXY_EOA =
    0x4200000000000000000000000000000000000009;
  address internal constant L2_STANDARD_BRIDGE =
    0x4200000000000000000000000000000000000010;
  address internal constant SEQUENCER_FEE_WALLET =
    0x4200000000000000000000000000000000000011;
  address internal constant L2_STANDARD_TOKEN_FACTORY =
    0x4200000000000000000000000000000000000012;
  address internal constant L1_BLOCK_NUMBER =
    0x4200000000000000000000000000000000000013;
  address internal constant OVM_GAS_PRICE_ORACLE =
    0x420000000000000000000000000000000000000F;
}