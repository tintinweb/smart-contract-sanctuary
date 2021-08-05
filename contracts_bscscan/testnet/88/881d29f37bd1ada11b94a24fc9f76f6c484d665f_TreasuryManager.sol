/**
 *Submitted for verification at BscScan.com on 2021-08-04
*/

//SPDX-License-Identifier: MIT

pragma solidity =0.6.12;

interface IBEP20 {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);
}

interface ITreasuryManager {
    function register(address regReferrer) external returns (bool);

    function register() external returns (bool);

    function deposit(uint256 _amount) external returns (bool);

    function withdraw(uint256 _amount) external returns (bool);

    function emergencyWithdraw() external returns (bool);

    function harvestWBNB() external returns (bool);

    function userPendingReward(address _user) external view returns (uint256);

    function usersInfo(address _user)
        external
        view
        returns (
            address,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        );

    function referrersInfo(address _referrer)
        external
        view
        returns (
            bool,
            uint256,
            uint256
        );

    function updateReward() external;
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

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
        assembly {
            codehash := extcodehash(account)
        }
        return (codehash != accountHash && codehash != 0x0);
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
    }

    function functionCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return
            functionCallWithValue(
                target,
                data,
                value,
                "Address: low-level call with value failed"
            );
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(
            address(this).balance >= value,
            "Address: insufficient balance for call"
        );
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(
        address target,
        bytes memory data,
        uint256 weiValue,
        string memory errorMessage
    ) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{value: weiValue}(
            data
        );
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

library SafeBEP20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(
        IBEP20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transfer.selector, to, value)
        );
    }

    function safeTransferFrom(
        IBEP20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transferFrom.selector, from, to, value)
        );
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IBEP20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IBEP20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require(
            (value == 0) || (token.allowance(msg.sender, spender) == 0),
            "SafeBEP20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.approve.selector, spender, value)
        );
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IBEP20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(
            data,
            "SafeBEP20: low-level call failed"
        );
        if (returndata.length > 0) {
            // Return data is optional
            // solhint-disable-next-line max-line-length
            require(
                abi.decode(returndata, (bool)),
                "SafeBEP20: BEP20 operation did not succeed"
            );
        }
    }
}

contract Ownable is Context {
    address private _owner;
    address private _previousOwner;
    uint256 private _lockTime;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    function getUnlockTime() public view returns (uint256) {
        return _lockTime;
    }

    //Locks the contract for owner for the amount of time provided
    function lock(uint256 time) public virtual onlyOwner {
        _previousOwner = _owner;
        _owner = address(0);
        _lockTime = now + time;
        emit OwnershipTransferred(_owner, address(0));
    }

    //Unlocks the contract for owner when _lockTime is exceeds
    function unlock() public virtual {
        require(
            _previousOwner == msg.sender,
            "You don't have permission to unlock"
        );
        require(now > _lockTime, "Contract is locked until end of locktime");
        emit OwnershipTransferred(_owner, _previousOwner);
        _owner = _previousOwner;
    }
}

interface ILigerRouter {
    function WETH() external pure returns (address);

    function swapExactTokensForTokenSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

abstract contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() internal {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }
}

contract TreasuryManager is ITreasuryManager, Ownable, ReentrancyGuard {
    using SafeBEP20 for IBEP20;
    using SafeMath for uint256;
    using Address for address;

    // Info of each user.
    struct UserInfo {
        address referrer; // Referrer Address.
        uint256 joinDate; // Register Date.
        uint256 lastDeposit; // Last Deposit LP
        uint256 rewardDebt; // To minus rewarded WBNB
        uint256 amountLP; // LP tokens that user has provided.
        uint256 harvestWBNB; // Total WBNB already harvest.
    }

    // Info of each referrer
    struct ReferrerInfo {
        bool excludedReferrer; // Addresses that excluded from referral
        uint256 referredCount; // referrer_address -> num_of_referred
        uint256 totalRewarded; // Total Referrer Rewarded
    }

    // Info of each user that stakes LP tokens.
    mapping(address => UserInfo) private userInfo;
    // Referral Mapping
    mapping(address => ReferrerInfo) private refInfo;

    // Treasury Fund Address
    address public TreasuryFund;
    // Operator Address
    address public Operator;

    // LP Address
    IBEP20 public LigerPairWBNB;
    // Liger Address
    IBEP20 public LigerDeFi;
    // Router
    ILigerRouter public LigerRouter;

    uint256 public TotalLPSupply;
    uint256 public TotalWBNBRewarded;
    uint256 private RatePerShareBefore;
    uint256 private RatePerShareCurrent;

    // Start with 3 Days Distribute Reward System
    // For Voting Support From Communnity
    // RewardTimeAdd will be decrease depend on
    // total VOTE from verified token voting website
    // to boost organic marketing by community help.
    uint256 public RewardTimeAdd = 60; //259200;
    uint256 public RewardTime = block.timestamp;

    // Referral Bonus default to 3% from User Reward
    uint256 public ReferrerReward = 3;
    // cooldown withdraw after deposit default 14 Days.
    uint256 public CoolDownWithdraw = 900; //1209600;
    // fee within 14 Days default
    uint256 public PenaltyFee = 5;
    // Minimum LP Deposit default
    uint256 public MinLPdeposit = 1000 * 10**18;
    // min token to swap default
    uint256 public MinTokenToSwap = 50 * 10**9 * 10**18;
    // Fee After Received LIGER => Swap => WBNB
    uint256 public TreasuryFee = 25; // = default 1% from LigerDeFi
    // Liquidity Provider Reward
    uint256 public LPStakingReward = 75; // = default 3% from LigerDeFi

    // Swap Enable
    bool public SwapEnabled = true;
    // Swap Modifier
    bool SwapAndLiquifyLock;
    // Distribute Enable
    bool public PausedReward = false;

    // Transaction Event
    event ReceivedWBNBafterSwap(
        uint256 WBNBbalanceBeforeSwap,
        uint256 LigerTokenSwapped,
        uint256 WBNBreceivedAfterSwap
    );
    event SendWBNBToTreasuryFund(
        address indexed TreasuryFund,
        uint256 TreasuryFeeAmount
    );
    event EmergencyWithdraw(
        address indexed User,
        uint256 AmountLPWithdraw,
        uint256 AmountWBNBWithdraw
    );
    event Register(address User, address Referrer);
    event Deposit(address User, uint256 AmountLP);
    event Withdraw(address User, uint256 AmountLP);
    event EarlyWithdrawFee(
        address User,
        address TreasuryFund,
        uint256 CoolDownWithdrawTime,
        uint256 PenaltyAmount
    );
    event HarvestWBNB(address User, uint256 AmountWBNB);
    event ReferReward(address Referrer, address User, uint256 AmountWBNB);

    //Update Event
    event UpdateExcludedReferrer(address Referrer, bool NewStatus);
    event UpdateRewardTimeAdd(uint256 NewRewardTimeAdd);
    event UpdateReferrerReward(uint256 newReferrerReward);
    event UpdateCoolDownWithdraw(uint256 NewCoolDownWithdraw);
    event UpdatePenaltyFee(uint256 NewPenaltyFee);
    event UpdateMinLPdeposit(uint256 NewMinLPamount);
    event UpdateMinTokenToSwap(uint256 NewMinTokenToSwap);
    event UpdateTreasuryFee(uint256 NewTreasuryFee, uint256 NewLPStakingReward);
    event UpdateTreasuryFund(address NewTreasuryFund);
    event UpdateOperator(address NewOperator);
    event UpdateSwapEnabled(bool NewStatus);
    event UpdatePausedReward(bool NewStatus);

    modifier lockTheSwap() {
        SwapAndLiquifyLock = true;
        _;
        SwapAndLiquifyLock = false;
    }

    modifier onlyOperatorOrOwner() {
        require(
            Operator == msg.sender || owner() == msg.sender,
            "TreasuryManager::Caller Not Operator or owner"
        );
        _;
    }

    constructor(
        address RouterAddress,
        address PairAddress,
        address LigerAddress,
        address TreasuryFundAddress
    ) public {
        Operator = msg.sender;
        LigerRouter = ILigerRouter(RouterAddress);
        LigerPairWBNB = IBEP20(PairAddress);
        LigerDeFi = IBEP20(LigerAddress);
        TreasuryFund = TreasuryFundAddress;
        uint256 approveAmount = 2**256 - 1;
        LigerDeFi.approve(address(LigerRouter), approveAmount);
    }

    //to receive BNB from Router when swaping
    //receive() external payable {}

    // Register Staking to Treasury Manager with referrar
    function register(address regReferrer)
        public
        override
        nonReentrant
        returns (bool)
    {
        UserInfo storage user = userInfo[msg.sender];
        ReferrerInfo storage refer = refInfo[regReferrer];
        require(
            msg.sender != regReferrer,
            "TreasuryManager::Forbidden Refer Yourself"
        );
        require(regReferrer == address(0), "TreasuryManager::Zero Address");
        require(
            !refer.excludedReferrer,
            "TreasuryManager::Referrer Blacklisted"
        );
        require(user.joinDate == 0, "TreasuryManager::Already Registered");
        uint256 approveAmount = 2**256 - 1; // OneTime Approve for this contract
        LigerPairWBNB.safeApprove(address(this), approveAmount);
        user.referrer = address(regReferrer);
        user.joinDate = block.timestamp;
        refer.referredCount += 1;
        emit Register(msg.sender, user.referrer);
        return true;
    }

    // Register Staking to Treasury Manager without referrar
    function register() public override nonReentrant returns (bool) {
        UserInfo storage user = userInfo[msg.sender];
        ReferrerInfo storage refer = refInfo[user.referrer];
        require(user.joinDate == 0, "TreasuryManager::Already Registered");
        uint256 approveAmount = 2**256 - 1; // OneTime Approve for this contract
        LigerPairWBNB.safeApprove(address(this), approveAmount);
        user.referrer = TreasuryFund;
        user.joinDate = block.timestamp;
        refer.referredCount += 1;
        emit Register(msg.sender, user.referrer);
        return true;
    }

    // Deposit LP tokens to TreasuryManager.
    function deposit(uint256 _amount)
        public
        override
        nonReentrant
        returns (bool)
    {
        UserInfo storage user = userInfo[msg.sender];
        uint256 LPBalance = LigerPairWBNB.balanceOf(msg.sender);
        require(user.joinDate != 0, "TreasuryManager::Unregistered User");
        require(_amount != 0, "TreasuryManager::Zero Amount Input");
        require(_amount <= LPBalance, "TreasuryManager::Insufficient LP Token");
        updateReward();
        if (user.amountLP > 0) {
            uint256 pendingWBNB = user
                .amountLP
                .mul(RatePerShareCurrent)
                .div(1e12)
                .sub(user.rewardDebt);
            ReferrerInfo storage refer = refInfo[user.referrer];
            if (pendingWBNB > 0) {
                uint256 RefReward = pendingWBNB.mul(ReferrerReward).div(10e2);
                if (!refer.excludedReferrer) {
                    IBEP20(LigerRouter.WETH()).safeTransfer(
                        user.referrer,
                        RefReward
                    );
                    refer.totalRewarded += RefReward;
                } else {
                    IBEP20(LigerRouter.WETH()).safeTransfer(
                        TreasuryFund,
                        RefReward
                    );
                }
                uint256 UserReward = pendingWBNB.sub(RefReward);
                IBEP20(LigerRouter.WETH()).safeTransfer(msg.sender, UserReward);
                user.harvestWBNB += UserReward;
                emit HarvestWBNB(msg.sender, UserReward);
                emit ReferReward(user.referrer, msg.sender, RefReward);
            }
        }
        if (_amount >= MinLPdeposit) {
            LigerPairWBNB.safeTransferFrom(
                address(msg.sender),
                address(this),
                _amount
            );
            user.amountLP = user.amountLP.add(_amount);
            TotalLPSupply = TotalLPSupply.add(_amount);
            user.lastDeposit = block.timestamp;
            emit Deposit(msg.sender, _amount);
        }
        user.rewardDebt = user.amountLP.mul(RatePerShareCurrent).div(1e12);
        return true;
    }

    // Withdraw LP tokens from TreasuryManager.
    function withdraw(uint256 _amount)
        public
        override
        nonReentrant
        returns (bool)
    {
        UserInfo storage user = userInfo[msg.sender];
        require(_amount != 0, "TreasuryManager::Zero Amount Input");
        require(
            _amount <= user.amountLP,
            "TreasuryManager::LP Stake Below Than Amount"
        );
        updateReward();
        uint256 amountLPwithdraw;
        uint256 pendingWBNB = user
            .amountLP
            .mul(RatePerShareCurrent)
            .div(1e12)
            .sub(user.rewardDebt);
        ReferrerInfo storage refer = refInfo[user.referrer];
        if (pendingWBNB > 0) {
            uint256 RefReward = pendingWBNB.mul(ReferrerReward).div(10e2);
            if (!refer.excludedReferrer) {
                IBEP20(LigerRouter.WETH()).safeTransfer(
                    user.referrer,
                    RefReward
                );
                refer.totalRewarded += RefReward;
            } else {
                IBEP20(LigerRouter.WETH()).safeTransfer(
                    TreasuryFund,
                    RefReward
                );
            }
            uint256 UserReward = pendingWBNB.mul(100 - ReferrerReward).div(
                10e2
            );
            IBEP20(LigerRouter.WETH()).safeTransfer(msg.sender, UserReward);
            user.harvestWBNB += UserReward;
            emit HarvestWBNB(msg.sender, UserReward);
            emit ReferReward(user.referrer, msg.sender, RefReward);
        }
        if (_amount <= user.amountLP) {
            uint256 coolDownCheck = user.lastDeposit.add(CoolDownWithdraw);
            amountLPwithdraw = _amount;
            if (block.timestamp <= coolDownCheck) {
                uint256 PenaltyAmount = amountLPwithdraw.mul(PenaltyFee).div(
                    10e2
                );
                amountLPwithdraw = amountLPwithdraw.sub(PenaltyAmount);
                IBEP20(LigerPairWBNB).safeTransfer(TreasuryFund, PenaltyAmount);
                emit EarlyWithdrawFee(
                    msg.sender,
                    TreasuryFund,
                    coolDownCheck,
                    PenaltyAmount
                );
            }
            LigerPairWBNB.safeTransfer(address(msg.sender), amountLPwithdraw);
            TotalLPSupply = TotalLPSupply.sub(_amount);
            user.amountLP = user.amountLP.sub(_amount);
        }
        user.rewardDebt = 0;
        emit Withdraw(msg.sender, amountLPwithdraw);
        return true;
    }

    function emergencyWithdraw() public override nonReentrant returns (bool) {
        UserInfo storage user = userInfo[msg.sender];
        updateReward();
        uint256 amountLPwithdraw;
        uint256 amountWBNBharvest;
        uint256 pendingWBNB = user
            .amountLP
            .mul(RatePerShareCurrent)
            .div(1e12)
            .sub(user.rewardDebt);
        ReferrerInfo storage refer = refInfo[user.referrer];
        if (pendingWBNB > 0) {
            uint256 RefReward = pendingWBNB.mul(ReferrerReward).div(10e2);
            if (!refer.excludedReferrer) {
                IBEP20(LigerRouter.WETH()).safeTransfer(
                    user.referrer,
                    RefReward
                );
                refer.totalRewarded += RefReward;
            } else {
                IBEP20(LigerRouter.WETH()).safeTransfer(
                    TreasuryFund,
                    RefReward
                );
            }
            uint256 UserReward = pendingWBNB.mul(100 - ReferrerReward).div(
                10e2
            );
            IBEP20(LigerRouter.WETH()).safeTransfer(msg.sender, UserReward);
            user.harvestWBNB += UserReward;
            amountWBNBharvest = UserReward;
            emit HarvestWBNB(msg.sender, UserReward);
            emit ReferReward(user.referrer, msg.sender, RefReward);
        }
        if (user.amountLP > 0) {
            uint256 coolDownCheck = user.lastDeposit.add(CoolDownWithdraw);
            amountLPwithdraw = user.amountLP;
            if (block.timestamp <= coolDownCheck) {
                uint256 PenaltyAmount = user.amountLP.mul(PenaltyFee).div(10e2);
                amountLPwithdraw = user.amountLP.sub(PenaltyAmount);
                IBEP20(LigerPairWBNB).safeTransfer(TreasuryFund, PenaltyAmount);
                emit EarlyWithdrawFee(
                    msg.sender,
                    TreasuryFund,
                    coolDownCheck,
                    PenaltyAmount
                );
            }
            LigerPairWBNB.safeTransfer(address(msg.sender), amountLPwithdraw);
            TotalLPSupply = TotalLPSupply.sub(user.amountLP);
            user.amountLP = 0;
        }
        user.rewardDebt = 0;
        emit EmergencyWithdraw(msg.sender, amountLPwithdraw, amountWBNBharvest);
        return true;
    }

    function harvestWBNB() public override nonReentrant returns (bool) {
        UserInfo storage user = userInfo[msg.sender];
        ReferrerInfo storage refer = refInfo[user.referrer];
        uint256 pendingWBNB = user
            .amountLP
            .mul(RatePerShareCurrent)
            .div(1e12)
            .sub(user.rewardDebt);
        if (pendingWBNB > 0) {
            uint256 RefReward = pendingWBNB.mul(ReferrerReward).div(10e2);
            if (!refer.excludedReferrer) {
                IBEP20(LigerRouter.WETH()).safeTransfer(
                    user.referrer,
                    RefReward
                );
                refer.totalRewarded += RefReward;
            } else {
                IBEP20(LigerRouter.WETH()).safeTransfer(
                    TreasuryFund,
                    RefReward
                );
            }
            uint256 UserReward = pendingWBNB.sub(RefReward);
            IBEP20(LigerRouter.WETH()).safeTransfer(msg.sender, UserReward);
            user.harvestWBNB += UserReward;
            emit HarvestWBNB(msg.sender, UserReward);
            emit ReferReward(user.referrer, msg.sender, RefReward);
        }
        user.rewardDebt = user.amountLP.mul(RatePerShareCurrent).div(1e12);
        return true;
    }

    function userPendingReward(address _user)
        public
        view
        override
        returns (uint256)
    {
        UserInfo storage user = userInfo[_user];
        uint256 grossReward = user
            .amountLP
            .mul(RatePerShareCurrent)
            .div(1e12)
            .sub(user.rewardDebt);
        uint256 ReferRewardDeduct = grossReward.mul(ReferrerReward).div(10e2);
        return grossReward.sub(ReferRewardDeduct);
    }

    function usersInfo(address _user)
        public
        view
        override
        returns (
            address MyReferrer,
            uint256 JoinDate,
            uint256 LastDeposit,
            uint256 RewardDebt,
            uint256 AmountLP,
            uint256 HarvestedWBNB
        )
    {
        UserInfo storage user = userInfo[_user];
        MyReferrer = user.referrer;
        JoinDate = user.joinDate;
        LastDeposit = user.lastDeposit;
        RewardDebt = user.rewardDebt;
        AmountLP = user.amountLP;
        HarvestedWBNB = user.harvestWBNB;
    }

    function referrersInfo(address _referrer)
        public
        view
        override
        returns (
            bool ExcludedReferrer,
            uint256 ReferredCount,
            uint256 TotalRewarded
        )
    {
        ReferrerInfo storage refer = refInfo[_referrer];
        ExcludedReferrer = refer.excludedReferrer;
        ReferredCount = refer.referredCount;
        TotalRewarded = refer.totalRewarded;
    }

    // Swap Received LIGER to WBNB
    function swapLigerForWBNB(uint256 tokenAmount) private lockTheSwap {
        // generate the liger pair path of token -> wbnb
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = LigerRouter.WETH();

        // make the swap
        LigerRouter.swapExactTokensForTokenSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    } // 0 is accept any amount of BNB

    function updateReward() public override {
        if (!PausedReward && block.timestamp >= RewardTime) {
            uint256 ligerTokenBalance = LigerDeFi.balanceOf(address(this));
            bool TokenSwap = ligerTokenBalance >= MinTokenToSwap;
            if (TokenSwap && SwapEnabled && !SwapAndLiquifyLock) {
                uint256 WBNBbalanceBeforeSwap = IBEP20(LigerRouter.WETH())
                    .balanceOf(address(this));
                swapLigerForWBNB(MinTokenToSwap); // Swap Liger For WBNB
                uint256 WBNBbalanceAfterSwap = IBEP20(LigerRouter.WETH())
                    .balanceOf(address(this));
                uint256 WBNBreceivedAfterSwap = WBNBbalanceAfterSwap.sub(
                    WBNBbalanceBeforeSwap
                );

                uint256 treasuryFee = WBNBreceivedAfterSwap
                    .mul(TreasuryFee)
                    .div(10e2);
                IBEP20(LigerRouter.WETH()).safeTransfer(
                    TreasuryFund,
                    treasuryFee
                );
                uint256 rewardBalance = WBNBreceivedAfterSwap.sub(treasuryFee);
                TotalWBNBRewarded += rewardBalance;
                RatePerShareBefore += RatePerShareCurrent;
                RatePerShareCurrent += rewardBalance.mul(1e12).div(
                    TotalLPSupply
                );
                RewardTime += RewardTimeAdd;
                emit ReceivedWBNBafterSwap(
                    WBNBbalanceBeforeSwap,
                    MinTokenToSwap,
                    WBNBreceivedAfterSwap
                );
                emit SendWBNBToTreasuryFund(TreasuryFund, treasuryFee);
            }
        }
    }

    // Update Function Manage By Operator And Deployer
    function updateExcludedReferrer(address referrer, bool newStatus)
        external
        onlyOperatorOrOwner
    {
        refInfo[referrer].excludedReferrer = newStatus;
        emit UpdateExcludedReferrer(referrer, newStatus);
    }

    function updateRewardTimeAdd(uint256 newRewardTimeAdd)
        external
        onlyOperatorOrOwner
    {
        RewardTimeAdd = newRewardTimeAdd;
        emit UpdateRewardTimeAdd(newRewardTimeAdd);
    }

    function updateReferrerReward(uint256 newReferrerReward)
        external
        onlyOperatorOrOwner
    {
        ReferrerReward = newReferrerReward;
        emit UpdateReferrerReward(newReferrerReward);
    }

    function updateCoolDownWithdraw(uint256 newCoolDownWithdraw)
        external
        onlyOperatorOrOwner
    {
        CoolDownWithdraw = newCoolDownWithdraw;
        emit UpdateCoolDownWithdraw(newCoolDownWithdraw);
    }

    function updatePenaltyFee(uint256 newPenaltyFee)
        external
        onlyOperatorOrOwner
    {
        PenaltyFee = newPenaltyFee;
        emit UpdatePenaltyFee(newPenaltyFee);
    }

    function updateMinLPdeposit(uint256 newMinLPdeposit)
        external
        onlyOperatorOrOwner
    {
        MinLPdeposit = newMinLPdeposit;
        emit UpdateMinLPdeposit(newMinLPdeposit);
    }

    function updateMinTokenToSwap(uint256 newMinTokenToSwap)
        external
        onlyOperatorOrOwner
    {
        MinTokenToSwap = newMinTokenToSwap;
        emit UpdateMinTokenToSwap(newMinTokenToSwap);
    }

    function updateTreasuryFee(uint256 newTreasuryFee)
        external
        onlyOperatorOrOwner
    {
        TreasuryFee = newTreasuryFee;
        LPStakingReward = 100 - newTreasuryFee;
        emit UpdateTreasuryFee(newTreasuryFee, LPStakingReward);
    }

    function updateTreasuryFund(address newTreasuryFund)
        external
        onlyOperatorOrOwner
    {
        TreasuryFund = newTreasuryFund;
        emit UpdateTreasuryFund(newTreasuryFund);
    }

    function updateOperator(address newOperator) external onlyOperatorOrOwner {
        Operator = newOperator;
        emit UpdateOperator(newOperator);
    }

    function updateSwapEnabled(bool newStatus) external onlyOperatorOrOwner {
        SwapEnabled = newStatus;
        emit UpdateSwapEnabled(newStatus);
    }

    function updatePausedReward(bool newStatus) external onlyOperatorOrOwner {
        PausedReward = newStatus;
        emit UpdatePausedReward(newStatus);
    }
}