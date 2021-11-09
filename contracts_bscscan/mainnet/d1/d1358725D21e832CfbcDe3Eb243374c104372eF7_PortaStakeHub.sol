/**
 *Submitted for verification at BscScan.com on 2021-11-09
*/

// Sources flattened with hardhat v2.6.4 https://hardhat.org

// SPDX-License-Identifier: AGPL-3.0-or-later

// File @openzeppelin/contracts/token/ERC20/[email protected]

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


// File @openzeppelin/contracts/utils/[email protected]

pragma solidity ^0.8.0;

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


// File @openzeppelin/contracts/access/[email protected]

pragma solidity ^0.8.0;

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


// File contracts/interface/IPortaStakeHub.sol

// IPortaStakeHub.sol -- Porta Staking Administration Interface

pragma solidity ^0.8.0;

// @title PortaStake Interface
// @author Alisina Bahadori
interface IPortaStakeHub {
    /*---------------------*\
    |  Interface functions  |
    \*---------------------*/

    // @notice Withdraws tokens from the contract by an administrator.
    // @param amount How much of the fungible token to withdraw.
    function adminWithdraw(uint256 amount) external;

    // @notice Sets the active stacking campaign for the contract.
    // @param apr The annual reward percentage. 100% = 10000.
    // @param maxTokens Max amount of tokens in the stake pool.
    // @param startAt When the campaign will lock the funds and accept stakes.
    // @param endAt When the campaign releases the lock and stops rewarding.
    // @param minStakeDuration Minimum time required for stake to be withdraw-able.
    function newCampaign(
        string memory title,
        uint256 apr,
        uint256 maxTokens,
        uint256 startAt,
        uint256 endAt,
        uint256 minStakeDuration,
        uint256 minStakePerAddress,
        uint256 maxStakePerAddress
    ) external returns (address campaignContract);

    // @notice Returns active campaign addresses.
    // @return isActive Determines if a campaign is activated.
    function listVaults() external view returns (address[] memory vaults);

    /*--------*\
    |  Events  |
    \*--------*/

    // @notice When an administrator withdraws an amount from the contract.
    event AdminWithdraw(address indexed admin, uint256 amount);

    // @notice When an administrator sets up a campaign for the contract.
    event CampaignCreate(address campaignContract);
}


// File contracts/struct/CampaignConfig.sol

// CampaignConfig.sol -- Struct for holding campaign configuration

pragma solidity ^0.8.0;

struct CampaignConfig {
    // Title of the campaign.
    string title;
    // APR of active campaign.
    uint256 apr;
    // How many tokens should be given away in case of max contribution.
    uint256 maxTokens;
    // When the campaign start and deposits can begin.
    uint256 startAt;
    // When campaign ends.
    uint256 endAt;
    // For how much time will the initial stake of address get locked.
    uint256 minStakeDuration;
    // Maximum number of tokens that can be staked per address.
    uint256 maxStakePerAddress;
    // Minimum number of tokens that can be staked per address.
    uint256 minStakePerAddress;
}


// File contracts/implementation/CreatorOwnable.sol

pragma solidity ^0.8.0;

// CreatorOwnable.sol -- An ownable abstraction with creator source


// @title CreatorOwnable
// @author Alisina Bahadori
// @dev Ownable abstraction which follows the ownable of the immutable creator.
abstract contract CreatorOwnable is Context {
    Ownable private immutable _creator;

    /**
     * @dev Initializes the contract setting the deployer as the creator.
     */
    constructor() {
        _creator = Ownable(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner based on creators owner.
     */
    function owner() public view virtual returns (address) {
        return _creator.owner();
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
}


// File contracts/interface/IPortaStake.sol

// IPortaStake.sol -- Porta Staking Interface

pragma solidity ^0.8.0;

// @title PortaStake Interface
// @author Alisina Bahadori
interface IPortaStake {
    /*---------*\
    |  Actions  |
    \*---------*/

    // @notice Stakes amount of token into the contract.
    // @param amount How much of the fungible token to deposit for staking.
    function depositStake(uint256 amount) external;

    // @notice Withdraws staked amount from the contract.
    // @param amount How much of the fungible token to unstake.
    function withdrawStake(uint256 amount) external;

    // @notice Claims the claimable reward for the sender.
    function claimReward() external returns (uint256 claimedReward);

    // @notice Withdraws all non-locked token only after the campaign ends.
    function finalWithdraw() external;

    /*-------*\
    |  Views  |
    \*-------*/

    // @notice Returns true if there is an active campaign.
    // @return isActive if the campaign is active.
    function isCampaignActive() external returns (bool isActive);

    // @notice Returns account information for dapps. This function should not
    // be used internally or by smart contracts as it consumes lots of gas.
    // @param owner The account address to get the info for.
    // @return stakeAmount the amount of staked tokens.
    // @return claimableReward amount of reward available to claim.
    // @return liveReward total amount of reward at this point in time.
    // @return lockedUntil Until when the withdrawal is locked for the owner.
    function accountInfo(address owner)
        external
        view
        returns (
            uint256 stakeAmount,
            uint256 claimableRewardAmount,
            uint256 liveRewardAmount,
            uint256 unlocksAt
        );

    // @notice Calculates the current reward for an owner. May not be claimable.
    // @param owner Address of the stake owner to calculate rewards for.
    // @return liveReward The amount live reward for address.
    function liveReward(address owner)
        external
        view
        returns (uint256 reward);

    // @notice Calculates the unclaimed reward for an owner.
    // @param owner Address of the stake owner to calculate rewards for.
    // @return claimableReward The amount of reward available to claim.
    function claimableReward(address owner)
        external
        view
        returns (uint256 reward);

    // @notice Returns the stake lock status for an owner.
    // @param owner Address of the stake owner to fetch lock status for.
    // @return lockedUntil The minimum time when withdrawal is possible.
    function lockedUntil(address owner)
        external
        view
        returns (uint256 unlocksAt);

    /*--------*\
    |  Events  |
    \*--------*/

    // @notice When the stake amount for an owner is changed.
    event StakeChange(address indexed owner, uint256 amount);

    // @notice When the reward is claimed for the user.
    event RewardClaim(address indexed owner, uint256 amount);

    // @notice When the reward is claimed for the user.
    event FinalWithdraw(address indexed owner, uint256 amount);
}


// File contracts/struct/StakeHolderInfo.sol

// StakeHolderInfo.sol -- Struct for stake holder information

pragma solidity ^0.8.0;

struct StakeHolderInfo {
    // When was the last change to the stake.
    uint256 lastTimestamp;
    // How much is the current stake.
    uint256 stakeAmount;
}


// File contracts/utils/PortaUtils.sol

// PortaUtils.sol -- Helper functions for porta staking framework.

pragma solidity ^0.8.0;

abstract contract PortaUtils {
    uint256 constant PERCENT = 10000;
    uint256 constant APR_DURATION = 365 days;

    // @notice Calculates the stake reward at a given point in time.
    function rewardAt(
        uint256 stakedAmount,
        uint256 startAt,
        uint256 endAt,
        uint256 apr,
        uint256 campaignEndAt
    )
        public
        pure
        returns (uint256)
    {
        if (startAt > endAt)
            return 0;
        if (endAt > campaignEndAt)
            endAt = campaignEndAt;

        return stakedAmount * (endAt - startAt) * apr / APR_DURATION / PERCENT;
    }
}


// File contracts/implementation/PortaStake.sol

// PortaStake.sol -- Porta Staking Contract

pragma solidity ^0.8.0;





// @title PortaStake Contract
// @author Alisina Bahadori
contract PortaStake is IPortaStake, PortaUtils, CreatorOwnable {

    /*-----------*\
    |  Constants  |
    \*-----------*/

    uint256 constant REWARD_START = 1632679200;
    uint256 constant REWARD_INTERVAL = 1 days;
    IERC20 internal _stakeToken;
    CampaignConfig public campaignConfig;

    /*---------*\
    |  Storage  |
    \*---------*/

    // @notice Information of stake holders
    mapping(address => StakeHolderInfo) public _stakeHolderInfo;
    uint256 internal _lockedTokens = 0;
    uint256 public campaignStakedTokens = 0;

    constructor(
        string memory title,
        address stakeToken,
        uint256 apr,
        uint256 maxTokens,
        uint256 startAt,
        uint256 endAt,
        uint256 minStakeDuration,
        uint256 minStakePerAddress,
        uint256 maxStakePerAddress
    ) {
        _stakeToken = IERC20(stakeToken);

        require(startAt > block.timestamp,
                "PortaStake: CampaignStart should be greater than CurrentTime");
        require(endAt - 1 days >= startAt,
                "PortaStake: CampaignEnd should be greater than its start by at least a day");
        require(apr > 0, "PortaStake: APR should be greater than zero");
        require(maxStakePerAddress >= minStakePerAddress, "PortaStake: Bad Min/Max configuration.");
        require(maxStakePerAddress > 0, "PortaStake: Max Address Stake should be greater than 0");

        campaignConfig.title = title;
        campaignConfig.apr = apr;
        campaignConfig.maxTokens = maxTokens;
        campaignConfig.startAt = startAt;
        campaignConfig.endAt = endAt;
        campaignConfig.minStakeDuration = minStakeDuration;
        campaignConfig.minStakePerAddress = minStakePerAddress;
        campaignConfig.maxStakePerAddress = maxStakePerAddress;
    }

    /*--------------------*\
    |  Staking Operations  |
    \*--------------------*/

    function depositStake(uint256 amount) public override {
        require(isCampaignActive(),
                "PortaStake: Cannot deposit in deactivated campaign.");

        StakeHolderInfo storage shi = _stakeHolderInfo[msg.sender];

        // Unlock all tokens temporarily
        _lockedTokens -= endWithdrawAmount(shi);

        // Add the stake to the users vault
        shi.stakeAmount += amount;
        shi.lastTimestamp = block.timestamp;

        // Add to total staked tokens
        campaignStakedTokens += amount;
        // Lock the new total reward for user
        _lockedTokens += endWithdrawAmount(shi);

        require(campaignStakedTokens <= campaignConfig.maxTokens,
                "PortaStake: Campaign max tokens reached!");
        require(shi.stakeAmount <= campaignConfig.maxStakePerAddress,
                "PortaStake: Maximum address stake limit reached");
        require(shi.stakeAmount >= campaignConfig.minStakePerAddress,
                "PortaStake: Minimum address stake not satisfied");

        // Transfer tokens from user
        require(_stakeToken.transferFrom(msg.sender, address(this), amount));

        emit StakeChange(msg.sender, shi.stakeAmount);
    }

    function withdrawStake(uint256 amount) public override {
        StakeHolderInfo storage shi = _stakeHolderInfo[msg.sender];
        require(shi.stakeAmount > 0, "PortaStake: Insufficient balance");
        require(shi.lastTimestamp + campaignConfig.minStakeDuration <= block.timestamp,
                "PortaStake: Minimum stake duration not satisfied");

        if (isCampaignActive()) {
            // Claim the rewards for the user before withdraw
            if(claimReward() > 0)
                // Reload the stake holder info
                shi = _stakeHolderInfo[msg.sender];
        }


        require(amount <= shi.stakeAmount, "PortaStake: Insufficient balance");

        // Unlock all tokens temporarily
        _lockedTokens -= endWithdrawAmount(shi);

        // Remove the stake from users vault
        shi.stakeAmount -= amount;
        shi.lastTimestamp = block.timestamp;

        // Lock the new total reward for user
        _lockedTokens += endWithdrawAmount(shi);
        campaignStakedTokens -= amount;

        require(shi.stakeAmount == 0 || shi.stakeAmount >= campaignConfig.minStakePerAddress,
                "PortaStake: Minimum address stake not satisfied");
        require(_stakeToken.transfer(msg.sender, amount));

        emit StakeChange(msg.sender, shi.stakeAmount);
    }

    function claimReward() public override returns (uint256 claimedReward) {
        require(isCampaignActive(),
                "PortaStake: Claim works for active campaign. Use withdraw after campaign ends");

        uint256 claimableAmount = claimableReward(msg.sender);

        if (claimableAmount > 0) {
            StakeHolderInfo storage shi = _stakeHolderInfo[msg.sender];

            shi.lastTimestamp = block.timestamp;
            _lockedTokens -= claimableAmount;

            require(_stakeToken.transfer(msg.sender, claimableAmount));

            emit RewardClaim(msg.sender, claimableAmount);
        }

        return claimableAmount;
    }

    function finalWithdraw() external override onlyOwner {
        require(campaignConfig.endAt < block.timestamp, "PortaStake: Campaign is still running");

        uint256 amount = availableTokens();
        require(_stakeToken.transfer(owner(), amount));
        emit FinalWithdraw(msg.sender, amount);
    }

    /*----------------*\
    |  View Functions  |
    \*----------------*/

    function liveReward(address owner)
        public
        view
        override
        returns (uint256)
    {
        StakeHolderInfo memory shi = _stakeHolderInfo[owner];
        return rewardAt(
            shi.stakeAmount,
            shi.lastTimestamp,
            block.timestamp,
            campaignConfig.apr,
            campaignConfig.endAt
        );
    }

    function claimableReward(address owner)
        public
        view
        override
        returns (uint256)
    {
        StakeHolderInfo memory shi = _stakeHolderInfo[owner];

        uint256 applicable_rounds = (block.timestamp - REWARD_START) / REWARD_INTERVAL;
        uint256 applicable_timestamp = REWARD_START + applicable_rounds * REWARD_INTERVAL;

        return rewardAt(
          shi.stakeAmount,
          shi.lastTimestamp,
          applicable_timestamp,
          campaignConfig.apr,
          campaignConfig.endAt
        );
    }

    function accountInfo(address owner)
        external
        view
        override
        returns (
            uint256 stakeAmount,
            uint256 claimableRewardAmount,
            uint256 liveRewardAmount,
            uint256 unlocksAt
        )
    {
        StakeHolderInfo memory shi = _stakeHolderInfo[owner];
        // Return zeros immediately if stake is zero
        if (shi.stakeAmount == 0) return (0, 0, 0, 0);

        stakeAmount = shi.stakeAmount;
        claimableRewardAmount = claimableReward(owner);
        liveRewardAmount = liveReward(owner);
        unlocksAt = lockedUntil(owner);
    }

    function endWithdrawAmount(StakeHolderInfo memory shi) internal view returns (uint256) {
        // Reward + Initial Stake
        return rewardAt(
                shi.stakeAmount,
                shi.lastTimestamp,
                campaignConfig.endAt,
                campaignConfig.apr,
                campaignConfig.endAt
        ) + shi.stakeAmount;
    }

    function lockedUntil(address owner)
        public
        view
        override
        returns (uint256)
    {
        StakeHolderInfo memory shi = _stakeHolderInfo[owner];
        return shi.lastTimestamp + campaignConfig.minStakeDuration;
    }

    function availableTokens() public view returns (uint256 amount) {
        return _stakeToken.balanceOf(address(this)) - _lockedTokens;
    }

    function isCampaignActive() public view override returns (bool isActive) {
        return campaignConfig.startAt <= block.timestamp && campaignConfig.endAt >= block.timestamp;
    }
}


// File contracts/implementation/PortaStakeHub.sol

// PortaStakeHub.sol -- Porta Staking Management Contract

pragma solidity ^0.8.0;





// @title PortaStakeHub Contract
// @author Alisina Bahadori
contract PortaStakeHub is IPortaStakeHub, PortaUtils, Ownable {

    /*---------*\
    |  Storage  |
    \*---------*/

    IERC20 internal _stakeToken;
    address[] private _vaults;

    constructor(address stakeToken) {
        _stakeToken = IERC20(stakeToken);
    }

    /*------------------*\
    |  Admin Operations  |
    \*------------------*/

    function adminWithdraw(uint256 amount) external override onlyOwner {
        require(_stakeToken.transfer(owner(), amount));
        emit AdminWithdraw(msg.sender, amount);
    }

    function newCampaign(
        string memory title,
        uint256 apr,
        uint256 maxTokens,
        uint256 startAt,
        uint256 endAt,
        uint256 minStakeDuration,
        uint256 minStakePerAddress,
        uint256 maxStakePerAddress
    ) external override onlyOwner returns (address stakeContractAddress) {
        PortaStake portaStake = new PortaStake(
            title,
            address(_stakeToken),
            apr,
            maxTokens,
            startAt,
            endAt,
            minStakeDuration,
            minStakePerAddress,
            maxStakePerAddress);

        uint256 maxReward = rewardAt(maxTokens, startAt, endAt, apr, endAt);

        // For better error handling
        require(maxReward <= stakeTokenBalance(), "PortaStakeHub: Insufficient tokens for campaign");
        require(_stakeToken.transfer(address(portaStake), maxReward));

        _vaults.push(address(portaStake));

        emit CampaignCreate(address(portaStake));

        return address(portaStake);
    }

    function listVaults() external override view returns (address[] memory vaults) {
        return _vaults;
    }

    function stakeTokenBalance() public view returns (uint256 balance) {
        return _stakeToken.balanceOf(address(this));
    }
}