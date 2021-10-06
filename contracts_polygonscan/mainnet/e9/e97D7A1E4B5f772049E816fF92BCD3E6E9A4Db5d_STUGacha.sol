/**
 *Submitted for verification at polygonscan.com on 2021-10-06
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

// File: @openzeppelin/contracts/utils/Context.sol

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol


/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol

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

// File: stm/gacha.sol

interface IGacha {
    function mint(address to, uint256 amount) external;
    function burn(address from, uint256 amount) external;
}

interface IPool {
    function distribute(uint256 amount) external;
}

interface IRandom {
    function getRandomNumber() external returns (bytes32);
    function setRandAddress(bytes32 requestId, address sender, uint256 prob) external;
}

contract STUGacha is Ownable {
    
    address public token;
    address public STU;
    address public unitToken;
    address private chainlink;
    address private staking;
    address public mktAddress;

    uint256 public nav;
    uint256 public totalStakedUnit;
    uint256 public totalStaked;
    uint256 public totalPlayed;

    uint256 public mktPool;
    uint256 public mktShareBPS;
    uint256 public poolShareBPS;
    uint256 public discountBPS;
    uint256 public discountSTMHold;
    uint256 public withdrawFeeBPS;
    uint256 public customFee;
    uint256 public houseEdgeBPS;
    uint256 public jackpotPool;
    bool public distToPool;

    mapping(address => bool) public isPlayingGacha;
    mapping(address => bool) public canGetGachaReward;
    uint256 private clOnProcess;
    bool private stopPlay;

    // Referral
    mapping(address => address) public inviter;
    mapping(address => uint256) public referralReward;
    uint256 public refRewardBPS;
    
    // decimal
    uint256 private USDCdecimal = 6;

    // STUGacha
    mapping(address => bool) public isPlayed;
    mapping(address => uint256) public playSize;
    mapping(address => uint256) private pendingFund;
    mapping(address => bool) public rewardCustomStatus;
    mapping(address => uint256) public playProb;
    mapping(address => bool) public getLastDiscount;
    mapping(address => uint256[5]) public currentGachaReward;

    event OnStake(address sender, uint256 amount);
    event OnUnstake(address sender, uint256 amount);
    event OnClaimRefReward(address sender, uint256 amount);
    event OnClaimGacha(address sender, uint256 amount);
    event UpdateGachaStatus(uint256 nav);
    event UpdateChainlink(address chainlink);

    constructor(address _unitToken) {
        token = 0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174; // USDC (use to bet)
        STU = 0x26ecd5FbE511fd2aBF67318CFcff006A4420b012; // kSTU
        staking = 0xf92ecdB459a8aEE491F635F9Fec16339c1b6d009;
        unitToken = _unitToken;
        mktAddress = owner();
        nav = 1 *  10 ** 18; //Start NAV
        refRewardBPS = 0; //Set Referal reward at 0.50%
        mktShareBPS = 5; //Set mkt sharing at 0.10%
        poolShareBPS = 35; //Set STU pool sharing at 0.75%
        discountBPS = 100; //Set STU discount at 1%
        discountSTMHold = 50000 * 10 ** 18; //Set 20,000 STM holding for discount
        withdrawFeeBPS = 25; // Withdrawal fee 0.25%
        customFee = 3; // Custom Game Fee 0.003 USDC
        houseEdgeBPS = 100;
    }

    function getDiscount(address sender) view public returns (bool) {
        return IERC20(STU).balanceOf(sender) >= discountSTMHold;
    }
    
    // prob is percentage min = 1 = 1% = 100x
    function customPlay(uint256 amount, uint256 prob, address _inviter) external {
        require(prob >= 1 && prob <= 98);
        buyAndRandom(amount, _inviter, prob);
    }
    
    function buyAndRandom (uint256 amount, address _inviter, uint256 prob) internal {
        require(canPlay());
        require(!isPlayingGacha[msg.sender]);
        if (_inviter == msg.sender) _inviter = address(0);
        if(!isPlayed[msg.sender] && _inviter != address(0)) inviter[msg.sender] = _inviter;
        uint256 payoutAmount = amount * 100 / prob;
        uint256 onePercentPayout = payoutAmount / 100;
        if (getDiscount(msg.sender)) {
            getLastDiscount[msg.sender] = true;
        } else {
            payoutAmount = payoutAmount - onePercentPayout;
            getLastDiscount[msg.sender] = false;
        }
        uint256 checkingAmount = payoutAmount - onePercentPayout; //payoff should be not over 1% of total prize pool.
        uint256 received = amount;
        uint256 addMkt = customFee * 10 ** (USDCdecimal - 3);
        uint256 receivedAfterDis = received + addMkt;
        uint256 addStaking = received * poolShareBPS / ( 10000 );
        uint256 price = amount;
        if(!isPlayed[msg.sender]) isPlayed[msg.sender] = true;
        playProb[msg.sender] = prob;
        require(checkingAmount <= totalStaked / 100);
        require(IERC20(token).balanceOf(msg.sender) >= receivedAfterDis);
        require(IERC20(token).transferFrom(msg.sender, address(this), receivedAfterDis));
        mktPool += addMkt;
        if(distToPool) {
            IERC20(token).approve(address(staking), addStaking);
            IPool(staking).distribute(addStaking);
        } else {
            IERC20(token).transfer(staking, addStaking);
        }
        uint256 commToInviter;
        if(inviter[msg.sender] != address(0)){
            commToInviter = received * refRewardBPS / 10000;
            referralReward[inviter[msg.sender]] += commToInviter;
        }
        (playSize[msg.sender], isPlayingGacha[msg.sender]) = (price, true);
        pendingFund[msg.sender] = receivedAfterDis - addMkt - addStaking - commToInviter;
        totalPlayed += received;
        clOnProcess += 1;
        bytes32 randId = IRandom(chainlink).getRandomNumber();
        IRandom(chainlink).setRandAddress(randId, msg.sender, prob);
    }
    
    function setGachaCustomStatus (address sender, bool status, bool _rewardCustom) external {
        require(msg.sender==chainlink, "Do not have permission");
        rewardCustomStatus[sender] = _rewardCustom;
        setGachaStatus(sender, status);
    }
    
    function setGachaStatus (address sender, bool status) internal {
        canGetGachaReward[sender] = status;
        updateNAV(sender);
        clOnProcess -= 1;
    }
    
    function updateNAV (address sender) internal {
        uint256 payout = getPendingPayout(sender);
        uint256 received = pendingFund[sender];
        if (received >= payout){
            totalStaked += received - payout;
        } else {
            totalStaked -= payout - received;
        }
        nav = totalStaked * 10 ** (18 + 18 - USDCdecimal) / totalStakedUnit;
        emit UpdateGachaStatus(nav);
    }
    
    // Without Jackpot
    function getPendingPayout (address sender) view internal returns (uint256) {
        uint256 payout;
        if(rewardCustomStatus[sender]){
            uint256 payoutBefore = playSize[sender] * 100 / playProb[sender];
            uint256 onePercent = payoutBefore / 100;
            uint256 edgePercent = payoutBefore * houseEdgeBPS / 10000;
            if (!getLastDiscount[sender]) payoutBefore = payoutBefore - onePercent;
            payout = payoutBefore - edgePercent;
        }
        return payout;
    }

    function claimGachaReward() external {
        require(canGetGachaReward[msg.sender], "Please wait to process");
        uint256 payout = getPendingPayout(msg.sender);
        if (payout != 0) {
            IERC20(token).approve(address(this), payout);
            require(
                IERC20(token).transferFrom(address(this), msg.sender, payout),
                "Failed due to failed transfer."
            );
        }
        isPlayingGacha[msg.sender] = false;
        canGetGachaReward[msg.sender] = false;
        rewardCustomStatus[msg.sender] = false;
        emit OnClaimGacha(msg.sender, payout);
    }

    function enterStaking(uint256 amount) external {
        require(
            IERC20(token).balanceOf(msg.sender) >= amount,
            "Cannot stake more than you hold."
        );

        _addStake(amount);

        require(
            IERC20(token).transferFrom(msg.sender, address(this), amount),
            "Stake failed due to failed transfer."
        );

        emit OnStake(msg.sender, amount);
    }

    function _addStake(uint256 _amount) internal {
        totalStaked += _amount;
        uint256 unitNum = _amount * 10 ** (18 + 18 - USDCdecimal) / nav;
        IGacha(unitToken).mint(msg.sender, unitNum);
        totalStakedUnit += unitNum;
    }

    function leaveStaking(uint256 _unit) external {
        require(
            IERC20(unitToken).balanceOf(msg.sender) >= _unit,
            "Cannot unstake more than you have staked."
        );
        require(
            canWithdraw(),
            "Cannot waitdraw in unavailable period"
        );
        uint256 amount = nav * _unit / 10 ** (18 + 18 - USDCdecimal);
        IGacha(unitToken).burn(msg.sender, _unit);
        totalStaked -= amount;
        totalStakedUnit -= _unit;
        uint256 fee = withdrawFeeBPS * amount / 10000;
        IERC20(token).approve(address(this), amount - fee);
        if (withdrawFeeBPS != 0){
            if(distToPool) {
                IERC20(token).approve(address(staking), fee);
                IPool(staking).distribute(fee);
            } else {
                IERC20(token).transfer(staking, fee);
            }
        }
        require(IERC20(token).transferFrom(address(this), msg.sender, amount - fee),"Unstake failed due to failed transfer.");

        emit OnUnstake(msg.sender, amount);
    }

    function canPlay () view public returns (bool) {
        return (!(getHour(block.timestamp) % 4 == 0 && getMinute(block.timestamp) >= 45) && !stopPlay);
    }
    
    function canWithdraw () view public returns (bool) {
        return (!canPlay () && clOnProcess == 0);
    }

    function getHour(uint256 timestamp) internal pure returns (uint256) {
        return uint256((timestamp / 60 / 60) % 24);
    }

    function getMinute(uint256 timestamp) internal pure returns (uint256) {
        return uint256((timestamp / 60) % 60);
    }

    function claimRefReward() external {
        require(
            referralReward[msg.sender] > 0,
            "You do not have any reward."
        );

        IERC20(token).approve(address(this), referralReward[msg.sender]);

        require(
            IERC20(token).transferFrom(address(this), msg.sender, referralReward[msg.sender]),
            "Claim failed due to failed transfer."
        );

        referralReward[msg.sender] = 0;

        emit OnClaimRefReward(msg.sender, referralReward[msg.sender]);
    }

    function claimMktShare() external {
        require(address(msg.sender) == mktAddress,"You do not have the permission.");
        require(mktPool > 0,"You do not have any reward.");

        require(
            IERC20(token).transfer(mktAddress, mktPool),
            "Claim failed due to failed transfer."
        );

        mktPool = 0;

        emit OnClaimMktShare(mktAddress, mktPool);
    }

    event OnClaimMktShare(address receiver, uint256 amount);
    event UpdateRefReward(uint256 amount);
    event UpdateMktShare(uint256 amount);
    event UpdateMktAddress(address mktAddress);
    event UpdateTreasuryAddress(address _gachaTreasury);
    event UpdatePoolShare(uint256 amount);
    event UpdateDiscountRate(uint256 amount);
    event UpdateDiscountSTMHold(uint256 amount);
    event UpdateStopPlay(bool stop);

    function setRefReward(uint256 amount) external onlyOwner {
        require(amount <= 100, "Referal Reward cannot be higher than 1 percentage");
        refRewardBPS = amount;
        emit UpdateRefReward(amount);
    }

    function setMktShare(uint256 amount) external onlyOwner {
        require(amount <= 20, "Mkt share cannot be higher than 0.20 percentage");
        mktShareBPS = amount;
        emit UpdateMktShare(amount);
    }

    function setMktAddress(address newAddress) external onlyOwner {
        require(newAddress != address(0), "Mkt address cannot be the zero address");
        mktAddress = address(newAddress);
        emit UpdateMktAddress(newAddress);
    }

    function setPoolShare(uint256 amount) external onlyOwner {
        require(amount <= 100, "Pool share cannot be higher than 1 percentage");
        poolShareBPS = amount;
        emit UpdatePoolShare(amount);
    }
    
    function setDiscountRate(uint256 amount) external onlyOwner {
        require(amount <= 100, "Discount cannot be higher than 1 percentage");
        discountBPS = amount;
        emit UpdateDiscountRate(amount);
    }
    
    function setDiscountSTMHold(uint256 amount) external onlyOwner {
        discountSTMHold = amount;
        emit UpdateDiscountSTMHold(amount);
    }

    function setChainlink(address _chainlink) external onlyOwner {
        require(_chainlink != address(0),"Invalid Address");
        chainlink = address(_chainlink);
        emit UpdateChainlink(_chainlink);
    }

    function setStopPlay(bool _stop) external onlyOwner {
        stopPlay = _stop;
        emit UpdateStopPlay(_stop);
    }
    
    function setWithdrawFee(uint256 _fee) external onlyOwner {
        require(_fee <= 100, "Cannot be over 1%");
        withdrawFeeBPS = _fee;
        emit UpdateWithdrawFeeBPS(_fee);
    }
    
    event UpdateWithdrawFeeBPS(uint256 withdrawFeeBPS);
    
    function setCustomFee(uint256 _fee) external onlyOwner {
        require(_fee <= 20, "Cannot be over 0.02 USDC"); // 1 = 0.001 USDC
        customFee = _fee;
        emit UpdateCustomFee(_fee);
    }
    
    event UpdateCustomFee(uint256 customFee);
    
    function setTokenSTU(address _token) external onlyOwner {
        require(_token != address(0), "Invalid Address");
        STU = _token;
        emit UpdateTokenSTU(_token);
    }
    
    event UpdateTokenSTU(address _token);
    
    function setPoolSTU(address _pool, bool _isDist) external onlyOwner {
        require(_pool != address(0), "Invalid Address");
        staking = _pool;
        distToPool = _isDist;
        emit UpdatePoolSTU(_pool, _isDist);
    }
    
    event UpdatePoolSTU(address _pool, bool _isDist);
    
    function setHouseEdge(uint256 _edge) external onlyOwner {
        require(_edge >= 50, "Must be over 0.50%");
        require(_edge <= 250, "Must be lower 2.50%");
        houseEdgeBPS = _edge;
        emit UpdateHouseEdge(_edge);
    }
    
    event UpdateHouseEdge(uint256 _edge);
}