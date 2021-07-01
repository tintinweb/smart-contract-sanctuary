// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;

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
pragma solidity 0.8.1;

/**
 * @title Linked to ILV Marker Interface
 *
 * @notice Marks smart contracts which are linked to IlluviumERC20 token instance upon construction,
 *      all these smart contracts share a common ilv() address getter
 *
 * @notice Implementing smart contracts MUST verify that they get linked to real IlluviumERC20 instance
 *      and that ilv() getter returns this very same instance address
 *
 * @author Basil Gorin
 */
interface ILinkedToILV {
  /**
   * @notice Getter for a verified IlluviumERC20 instance address
   *
   * @return IlluviumERC20 token instance address smart contract is linked to
   */
  function ilv() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;

import "./ILinkedToILV.sol";

interface ILockedPool is ILinkedToILV {
    function vault() external view returns (address);

    function tokenLocking() external view returns (address);

    function vaultRewardsPerToken() external view returns (uint256);

    function poolTokenReserve() external view returns (uint256);

    function balanceOf(address _staker) external view returns (uint256);

    function pendingVaultRewards(address _staker) external view returns (uint256);

    function stakeLockedTokens(address _staker, uint256 _amount) external;

    function unstakeLockedTokens(address _staker, uint256 _amount) external;

    function changeLockedHolder(address _from, address _to) external;

    function receiveVaultRewards(uint256 _amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;

import "../token/IlluviumERC20.sol";
import "../interfaces/ILinkedToILV.sol";

/**
 * @title Illuvium Aware
 *
 * @notice Helper smart contract to be inherited by other smart contracts requiring to
 *      be linked to verified IlluviumERC20 instance and performing some basic tasks on it
 *
 * @author Basil Gorin
 */
abstract contract IlluviumAware is ILinkedToILV {
  /// @dev Link to ILV ERC20 Token IlluviumERC20 instance
  address public immutable override ilv;

  /**
   * @dev Creates IlluviumAware instance, requiring to supply deployed IlluviumERC20 instance address
   *
   * @param _ilv deployed IlluviumERC20 instance address
   */
  constructor(address _ilv) {
    // verify ILV address is set and is correct
    require(_ilv != address(0), "ILV address not set");
    require(IlluviumERC20(_ilv).TOKEN_UID() == 0x83ecb176af7c4f35a45ff0018282e3a05a1018065da866182df12285866f5a2c, "unexpected TOKEN_UID");

    // write ILV address
    ilv = _ilv;
  }

  /**
   * @dev Executes IlluviumERC20.safeTransferFrom(address(this), _to, _value, "")
   *      on the bound IlluviumERC20 instance
   *
   * @dev Reentrancy safe due to the IlluviumERC20 design
   */
  function transferIlv(address _to, uint256 _value) internal {
    // just delegate call to the target
    transferIlvFrom(address(this), _to, _value);
  }

  /**
   * @dev Executes IlluviumERC20.transferFrom(_from, _to, _value)
   *      on the bound IlluviumERC20 instance
   *
   * @dev Reentrancy safe due to the IlluviumERC20 design
   */
  function transferIlvFrom(address _from, address _to, uint256 _value) internal {
    // just delegate call to the target
    IlluviumERC20(ilv).transferFrom(_from, _to, _value);
  }

  /**
   * @dev Executes IlluviumERC20.mint(_to, _values)
   *      on the bound IlluviumERC20 instance
   *
   * @dev Reentrancy safe due to the IlluviumERC20 design
   */
  function mintIlv(address _to, uint256 _value) internal {
    // just delegate call to the target
    IlluviumERC20(ilv).mint(_to, _value);
  }

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;

import "../interfaces/ILockedPool.sol";
import "../interfaces/IERC20.sol";
import "./IlluviumAware.sol";
import "./TokenLocking.sol";
import "../utils/Ownable.sol";

contract IlluviumLockedPool is ILockedPool, IlluviumAware {
    /**
     * @dev Smart contract unique identifier, a random number
     * @dev Should be regenerated each time smart contact source code is changed
     *      and changes smart contract itself is to be redeployed
     * @dev Generated using https://www.random.org/bytes/
     */
    uint256 public constant POOL_UID = 0x620bbda48b8ff3098da2f0033cbf499115c61efdd5dcd2db05346782df6218e7;

    // @dev Data struct to store information about locked token staker
    struct User {
        // @dev Total staked amount
        uint256 tokenAmount;
        // @dev Auxiliary variable for vault rewards calculation
        uint256 subVaultRewards;
    }

    /// @dev Link to deployed IlluviumVault instance
    address public override vault;

    /// @dev Link to deployed TokenLocking instance
    address public override tokenLocking;

    /// @dev Used to calculate vault rewards
    /// @dev This value is different from "reward per weight" used in other pools
    /// @dev Note: locked pool doesn't operate on weights since all stakes are equal in duration
    uint256 public override vaultRewardsPerToken;

    /// @dev Total value of ILV tokens available in the pool
    uint256 public override poolTokenReserve;

    /// @dev Locked pool stakers mapping, maps staker addr => staker data struct (User)
    mapping(address => User) public users;

    /**
     * @dev Rewards per token can be small values, usually fitting into (0, 1) bounds.
     *      We store these values multiplied by 1e12, as integers.
     */
    uint256 private constant REWARD_PER_TOKEN_MULTIPLIER = 1e12;

    /**
     * @dev Fired in _stake()
     *
     * @param _from token holder address, the tokens will be returned to that address
     * @param amount amount of tokens staked
     */
    event Staked(address indexed _from, uint256 amount);

    /**
     * @dev Fired in _unstake()
     *
     * @param _to an address which received the unstaked tokens, usually token holder
     * @param amount amount of tokens unstaked
     */
    event Unstaked(address indexed _to, uint256 amount);

    /**
     * @dev Fired in _processVaultRewards() and dependent functions, like processRewards()
     *
     * @param _by an address which executed the function
     * @param _to an address which received a reward
     * @param amount amount of reward received
     */
    event VaultRewardsClaimed(address indexed _by, address indexed _to, uint256 amount);

    /**
     * @dev Fired in receiveVaultRewards()
     *
     * @param _by an address that sent the rewards, always a vault
     * @param amount amount of tokens received
     */
    event VaultRewardsReceived(address indexed _by, uint256 amount);

    /**
     * @dev Fired in setVault()
     *
     * @param _by an address which executed the function, always a factory owner
     */
    event VaultUpdated(address indexed _by, address _fromVal, address _toVal);

    /**
     * @dev Defines TokenLocking only access
     */
    modifier onlyTokenLocking() {
        // verify the access
        require(msg.sender == tokenLocking, "access denied");
        // execute rest of the function marked with the modifier
        _;
    }

    /**
     * @dev Deploys LockedPool linked to the previously deployed ILV token
     *      and TokenLocking addresses
     *
     * @param _ilv ILV ERC20 token instance deployed address
     * @param _tokenLocking TokenLocking instance deployed address the pool is bound to
     */
    constructor(address _ilv, address _tokenLocking) IlluviumAware(_ilv) {
        // verify the inputs
        require(_tokenLocking != address(0), "TokenLocking address is not set");

        // verify token locking smart contract is an expected one
        require(
            TokenLocking(_tokenLocking).LOCKING_UID() ==
                0x76ff776d518e4c1b71ef4a1af2227a94e9868d7c9ecfa08e9255d2360e18f347,
            "unexpected LOCKING_UID"
        );

        // internal state init
        tokenLocking = _tokenLocking;
    }

    /**
     * @dev Converts stake amount to ILV reward value, applying the 1e12 division on the token amount
     *      to correct for the fact that "rewards per token" are stored multiplied by 1e12
     *
     * @param _tokens amount of tokens to convert to reward
     * @param _rewardPerToken reward per token
     *      (this value is supplied multiplied by 1e12 and thus the need for division on the result)
     * @return _reward reward value normalized to 1e12
     */
    function tokensToReward(uint256 _tokens, uint256 _rewardPerToken) public pure returns (uint256 _reward) {
        // apply the formula and return
        return (_tokens * _rewardPerToken) / REWARD_PER_TOKEN_MULTIPLIER;
    }

    /**
     * @dev Derives reward per token given total reward and total tokens value
     *      Naturally the result would by just a division _reward/_tokens if not
     *      the requirement to store the result as an integer - therefore the result
     *      is represented multiplied by 1e12, as an integer
     *
     * @param _reward total amount of reward
     * @param _tokens total amount of tokens
     * @return _rewardPerToken reward per token (this value is returned multiplied by 1e12)
     */
    function rewardPerToken(uint256 _reward, uint256 _tokens) public pure returns (uint256 _rewardPerToken) {
        // apply the formula and return
        return (_reward * REWARD_PER_TOKEN_MULTIPLIER) / _tokens;
    }

    /**
     * @notice Calculates current vault rewards value available for address specified
     *
     * @dev Performs calculations based on current smart contract state only,
     *      not taking into account any additional time/blocks which might have passed
     *
     * @param _staker an address to calculate vault rewards value for
     * @return pending calculated vault reward value for the given address
     */
    function pendingVaultRewards(address _staker) public view override returns (uint256 pending) {
        User memory user = users[_staker];

        return tokensToReward(user.tokenAmount, vaultRewardsPerToken) - user.subVaultRewards;
    }

    /**
     * @dev Returns locked holder staked balance
     *
     * @param _staker address to check locked tokens balance
     */
    function balanceOf(address _staker) external view override returns (uint256 balance) {
        balance = users[_staker].tokenAmount;
    }

    /**
     * @dev Executed only by the factory owner to Set the vault
     *
     * @param _vault an address of deployed IlluviumVault instance
     */
    function setVault(address _vault) external {
        // verify function is executed by the factory owner
        require(Ownable(tokenLocking).owner() == msg.sender, "access denied");

        // verify input is set
        require(_vault != address(0), "zero input");

        // emit an event
        emit VaultUpdated(msg.sender, vault, _vault);

        // update vault address
        vault = _vault;
    }

    /**
     * @dev Executed by the TokenLocking instance to stake
     *      locked tokens on behalf of their holders
     *
     * @param _staker locked tokens holder address
     * @param _amount amount of the tokens staked
     */
    function stakeLockedTokens(address _staker, uint256 _amount) external override onlyTokenLocking {
        _stake(_staker, _amount);
    }

    /**
     * @dev Executed by the TokenLocking instance to unstake
     *      locked tokens on behalf of their holders
     *
     * @param _staker locked tokens holder address
     * @param _amount amount of the tokens to be unstaked
     */
    function unstakeLockedTokens(address _staker, uint256 _amount) external override onlyTokenLocking {
        _unstake(_staker, _amount);
    }

    /**
     * @dev Calculates vault rewards for the transaction sender and sends these rewards immediately
     *
     * @dev calls internal _processVaultRewards and passes _staker as msg.sender
     */
    function processVaultRewards() external {
        _processVaultRewards(msg.sender);
    }

    /**
     * @dev Executed by the vault to transfer vault rewards ILV from the vault
     *      into the pool
     *
     * @param _rewardsAmount amount of ILV rewards to transfer into the pool
     */
    function receiveVaultRewards(uint256 _rewardsAmount) external override {
        require(msg.sender == vault, "access denied");
        // return silently if there is no reward to receive
        if (_rewardsAmount == 0) {
            return;
        }
        require(poolTokenReserve > 0, "zero reserve");

        transferIlvFrom(msg.sender, address(this), _rewardsAmount);

        vaultRewardsPerToken += rewardPerToken(_rewardsAmount, poolTokenReserve);
        poolTokenReserve += _rewardsAmount;

        emit VaultRewardsReceived(msg.sender, _rewardsAmount);
    }

    /**
     * @dev Executed by token locking contract, by changing a locked token owner
     *      after verifying the signature.
     * @dev Inputs are validated by the caller - TokenLocking smart contract
     *
     * @param _from account to move tokens from
     * @param _to account to move tokens to
     */
    function changeLockedHolder(address _from, address _to) external override onlyTokenLocking {
        users[_to] = users[_from];
        delete users[_from];
    }

    /**
     * @dev Used internally, mostly by children implementations, see stake()
     *
     * @param _staker an address which stakes tokens and which will receive them back
     * @param _amount amount of tokens to stake
     */
    function _stake(address _staker, uint256 _amount) private {
        // validate the inputs
        require(_amount > 0, "zero amount");
        _processVaultRewards(_staker);

        User storage user = users[_staker];
        user.tokenAmount += _amount;
        poolTokenReserve += _amount;
        user.subVaultRewards = tokensToReward(user.tokenAmount, vaultRewardsPerToken);

        // emit an event
        emit Staked(_staker, _amount);
    }

    /**
     * @dev Used internally, mostly by children implementations, see unstake()
     *
     * @param _staker an address which unstakes tokens (which previously staked them)
     * @param _amount amount of tokens to unstake
     */
    function _unstake(address _staker, uint256 _amount) private {
        // verify an amount is set
        require(_amount > 0, "zero amount");
        User storage user = users[_staker];
        require(user.tokenAmount >= _amount, "not enough balance");
        _processVaultRewards(_staker);
        user.tokenAmount -= _amount;
        poolTokenReserve -= _amount;
        user.subVaultRewards = tokensToReward(user.tokenAmount, vaultRewardsPerToken);

        // emit an event
        emit Unstaked(_staker, _amount);
    }

    /**
     * @dev Calculates vault rewards for the `_staker` and sends these rewards immediately
     *
     * @dev Used internally to process vault rewards for the staker
     *
     * @param _staker address of the user (staker) to process rewards for
     */
    function _processVaultRewards(address _staker) private {
        User storage user = users[_staker];
        uint256 pendingVaultClaim = pendingVaultRewards(_staker);
        if (pendingVaultClaim == 0) return;
        // read ILV token balance of the pool via standard ERC20 interface
        uint256 ilvBalance = IERC20(ilv).balanceOf(address(this));
        require(ilvBalance >= pendingVaultClaim, "contract ILV balance too low");
        // protects against rounding errors
        poolTokenReserve -= pendingVaultClaim > poolTokenReserve ? poolTokenReserve : pendingVaultClaim;

        user.subVaultRewards = tokensToReward(user.tokenAmount, vaultRewardsPerToken);

        transferIlv(_staker, pendingVaultClaim);

        emit VaultRewardsClaimed(msg.sender, _staker, pendingVaultClaim);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;

import "../interfaces/ILockedPool.sol";
import "./IlluviumAware.sol";
import "./IlluviumLockedPool.sol";
import "../utils/Ownable.sol";

/**
 * @title Token Locking
 *
 * @notice A token holder contract that can release its token balance gradually like a
 *      typical vesting scheme, with a cliff and vesting period.
 * @notice Supports token staking for the tokens locked; staking is powered by IlluviumLockedPool (locked tokens pool)
 *
 * @notice Smart contract is deployed/initialized in 4 steps. During the initialization period the
 *      deployer is able to set locked token holders' balances and finally set the locked tokens pool
 *      to enable staking. Once final step is complete the deployer no longer can do that.
 *
 * @dev To initialize:
 *      1) deploy this smart contract (prerequisite: ILV token deployed)
 *      2) set the locked token holders and balances with `setBalances`
 *      3) transfer ILV in the amount equal to the sum of all holders' balances to the deployed instance
 *      4) [optional] set the Locked Token Pool with `setPool` (staking won't work until this is done)
 *
 * @dev The purpose of steps 2 and 3 is to have team and pre-seed investors tokens locked immediately,
 *      without giving them an ability not to lock them; in the same time we preserve an ability to stake
 *      these locked tokens
 *
 * @dev TokenLocking contract works with the token amount up to 10^7, which makes it safe
 *      to use uint96 for token amounts in the contract
 *
 * @dev Inspired by OpenZeppelin's TokenVesting.sol draft
 *
 * @author Pedro Bergamini, reviewed by Basil Gorin
 */
contract TokenLocking is Ownable, IlluviumAware {
    /**
     * @dev Smart contract unique identifier, a random number
     * @dev Should be regenerated each time smart contact source code is changed
     *      and changes smart contract itself is to be redeployed
     * @dev Generated using https://www.random.org/bytes/
     */
    uint256 public constant LOCKING_UID = 0x76ff776d518e4c1b71ef4a1af2227a94e9868d7c9ecfa08e9255d2360e18f347;

    /// @dev Keeps the essential user data required to return (unlock) locked tokens
    struct UserRecord {
        // @dev Amount of the currently locked ILV tokens
        uint96 ilvBalance;
        // @dev ILV already unlocked (during linear unlocking period for example)
        //      Total amount of holder's tokens is the sum `balance + released`
        uint96 ilvReleased;
        // @dev Flag indicating if holder's balance was staked (sent to  Pool)
        bool hasStaked;
    }

    /// @dev Maps locked token holder address to their user record (see above)
    mapping(address => UserRecord) public userRecords;

    /// @dev Enumeration of all the locked token holders
    address[] public lockedHolders;

    /// @dev When the linear unlocking starts, unix timestamp
    uint64 public immutable cliff;
    /// @dev How long the linear unlocking takes place, seconds
    uint32 public immutable duration;

    /// @dev Link to Locked Pool used to stake locked tokens and receive vault rewards
    IlluviumLockedPool public pool;

    /// @dev Nonces to support EIP-712 based token migrations
    mapping(address => uint256) public migrationNonces;

    /**
     * @notice EIP-712 contract's domain typeHash,
     *      see https://eips.ethereum.org/EIPS/eip-712#rationale-for-typehash
     */
    bytes32 public constant DOMAIN_TYPEHASH =
        keccak256("EIP712Domain(string name,uint256 chainId,address verifyingContract)");

    /**
     * @notice EIP-712 contract's domain separator,
     *      see https://eips.ethereum.org/EIPS/eip-712#definition-of-domainseparator
     */
    bytes32 public immutable DOMAIN_SEPARATOR;

    /**
     * @notice EIP-712 token migration struct typeHash,
     *      see https://eips.ethereum.org/EIPS/eip-712#rationale-for-typehash
     */
    bytes32 public constant MIGRATION_TYPEHASH =
        keccak256("Migration(address from,address to,uint256 nonce,uint256 expiry)");

    /// @dev Fired in release(), triggered by regular users (locked token holders)
    event TokensReleased(address indexed holder, uint96 amountIlv);
    /// @dev Fired in stake(), triggered by regular users (locked token holders)
    event TokensStaked(address indexed _by, address indexed pool, uint96 amount);
    /// @dev Fired in _unstakeIlv(), triggered by regular users (locked token holders)
    event TokensUnstaked(address indexed _by, address indexed pool, uint96 amount);
    /// @dev Fired in setPool(), triggered by admins only
    event PoolUpdated(address indexed _by, address indexed poolAddr);
    /// @dev Fired in setBalances(), triggered by admins only
    event LockedBalancesSet(address indexed _by, uint32 recordsNum, uint96 totalAmount);
    /// @dev Fired in migrateTokens(), triggered by admin only
    event TokensMigrated(address indexed _from, address indexed _to);

    /**
     * @dev Creates a token locking contract which integrates with the locked pool for token staking
     *      and implements linear unlocking mechanism starting at `_cliff` and lasting for `_duration`
     *
     * @param _cliff unix timestamp when the unlocking starts
     * @param _duration linear unlocking period (duration)
     * @param _ilv an address of the ILV ERC20 token
     */
    constructor(
        uint64 _cliff,
        uint32 _duration,
        address _ilv
    ) IlluviumAware(_ilv) {
        // verify the input parameters are set
        require(_cliff > 0, "cliff is not set (zero)");
        require(_duration > 0, "duration is not set (zero)");

        // init the variables
        cliff = _cliff;
        duration = _duration;

        // init the EIP-712 contract domain separator
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(DOMAIN_TYPEHASH, keccak256(bytes("TokenLocking")), block.chainid, address(this))
        );
    }

    /**
     * @dev Restricted access function to be executed by smart contract owner (admin)
     *      as a part of initialization process (step 4 - last step)
     * @dev Sets the Pool to be used for ILV staking, see `stake()`
     *
     * @dev Can be executed only once, throws if an attempt to set pool again is made
     * @dev Requires to be executed by smart contract owner
     *
     * @param _pool an address of the Pool to set
     */
    function setPool(IlluviumLockedPool _pool) external onlyOwner {
        // verify the input address is set (not zero)
        require(address(_pool) != address(0), "Pool address is not specified (zero)");
        // check that Pool was not already set before
        require(address(pool) == address(0), "Pool is already set");

        // verify the pool is of the expected type
        require(
            _pool.POOL_UID() == 0x620bbda48b8ff3098da2f0033cbf499115c61efdd5dcd2db05346782df6218e7,
            "unexpected POOL_UID"
        );

        // setup the locked tokens pool address
        pool = _pool;

        // emit an event
        emit PoolUpdated(msg.sender, address(_pool));
    }

    /**
     * @dev Restricted access function to be executed by smart contract owner (admin)
     *      as a part of initialization process (step 2)
     * @dev Sets the balances of the token owners, effectively allowing these balances to
     *      be staked and released when time comes, see `stake()`, see `release()`
     *
     * @dev Can be executed only before locked pool is set with `setPool`
     *
     * @dev Each execution overwrites the result of the previous one.
     *      Function cannot be effectively used to set bigger number of locked token holders
     *      that fits into a single block, which, however, is not required since
     *      the number of locked token holders doesn't exceed 100
     *
     * @dev Requires to be executed by smart contract owner
     * @dev Requires `owners` and `amounts` arrays sizes to match
     *
     * @param holders token holders array
     * @param amounts token holders corresponding balances
     */
    function setBalances(
        address[] memory holders,
        uint96[] memory amounts,
        uint96 expectedTotal
    ) external onlyOwner {
        // verify arrays lengths match
        require(holders.length == amounts.length, "input arr lengths mismatch");

        // we're not going to touch balances once the pool is set and staking becomes possible
        require(address(pool) == address(0), "too late: pool is already set");

        // we're not going to touch balances once linear unlocking phase starts
        require(now256() < cliff, "too late: unlocking already begun");

        // erase previously set mappings if any
        for (uint256 i = 0; i < lockedHolders.length; i++) {
            // delete old user record
            delete userRecords[lockedHolders[i]];
        }

        // update the locked holders enumeration
        lockedHolders = holders;

        // total amount set - to be used in LockedBalancesSet event log
        uint96 totalAmount = 0;

        // iterate the data supplied,
        for (uint256 i = 0; i < holders.length; i++) {
            // verify the inputs
            require(holders[i] != address(0), "zero holder address found");
            require(amounts[i] != 0, "zero amount found");

            // ensure input holders array doesn't have non-zero duplicates
            require(userRecords[holders[i]].ilvBalance == 0, "duplicate addresses found");

            // update user record's balance value (locked tokens amount)
            userRecords[holders[i]].ilvBalance = amounts[i];

            // update total amount
            totalAmount += amounts[i];
        }

        // ensure total amount is as expected
        require(totalAmount == expectedTotal, "unexpected total");

        // emit an event
        emit LockedBalancesSet(msg.sender, uint32(holders.length), totalAmount);
    }

    /**
     * @dev Reads the ILV balance of the token holder
     *
     * @param holder locked tokens holder address
     * @return token holder locked balance (ILV)
     */
    function balanceOf(address holder) external view returns (uint96) {
        // read from the storage and return
        return userRecords[holder].ilvBalance;
    }

    /**
     * @notice Checks if an address supplied has staked its tokens

     * @dev A shortcut to userRecords.hasStaked flag
     *
     * @param holder an address to query staked flag for
     * @return whether the token holder has already staked or not
     */
    function hasStaked(address holder) external view returns (bool) {
        // read from the storage and return
        return userRecords[holder].hasStaked;
    }

    /**
     * @notice Transfers vested tokens back to beneficiary, is executed after
     *      locked tokens get unlocked (at least partially)
     *
     * @notice When releasing the staked tokens `useSILV` determines if the reward
     *      is returned back as an sILV token (true) or if an ILV deposit is created (false)
     *
     * @dev Throws if executed before `cliff` timestamp
     * @dev Throws if there are no tokens to release
     */
    function release() external {
        UserRecord storage userRecord = userRecords[msg.sender];
        // calculate how many tokens are available for the sender to withdraw
        uint96 unreleasedIlv = releasableAmount(msg.sender);

        // ensure there are some tokens to withdraw
        require(unreleasedIlv > 0, "no tokens are due");

        // update balance and released user counters
        userRecord.ilvBalance -= unreleasedIlv;
        userRecord.ilvReleased += unreleasedIlv;

        // when the tokens were previously staked
        if (userRecord.hasStaked) {
            // unstake these tokens - delegate to internal `_unstakeIlv`
            _unstakeIlv(unreleasedIlv);
        }
        // transfer the tokens back to the holder
        transferIlv(msg.sender, unreleasedIlv);

        // emit an event
        emit TokensReleased(msg.sender, unreleasedIlv);
    }

    /**
     * @notice Stakes the tokens into the Pool,
     *      effectively transferring them into the pool;
     *      can be called by the locked token holders only once
     *
     * @dev Throws if Pool is not set (see initialization), if holder has already staked
     *      or of holder is not registered within the smart contract and its balance is zero
     */
    function stake() external {
        // verify Pool address has been set
        require(address(pool) != address(0), "pool is not set");

        // get a link to a user record
        UserRecord storage userRecord = userRecords[msg.sender];

        // verify holder hasn't already staked
        require(!userRecord.hasStaked, "tokens already staked");

        // read holder's balance into the stack
        uint96 amount = userRecord.ilvBalance;

        // verify the balance is positive
        require(amount > 0, "nothing to stake");

        // update the staked flag in user records
        userRecord.hasStaked = true;

        // transfer the tokens into the pool, staking them
        pool.stakeLockedTokens(msg.sender, amount);

        // emit an event
        emit TokensStaked(msg.sender, address(pool), amount);
    }

    // @dev Releases staked ilv tokens, called internally
    function _unstakeIlv(uint96 amount) private {
        // unstake from the pool
        // we assume locking deposit is #0 which is by design of pool
        pool.unstakeLockedTokens(msg.sender, amount);
        // and emit an event
        emit TokensUnstaked(msg.sender, address(pool), amount);
    }

    /**
     * @notice Moves locked tokens between two addresses. Designed to be used
     *      in emergency situations when locked token holder suspects their
     *      account credentials ware revealed
     *
     * @dev Executed by contract owner on behalf of the locked tokens holder
     *
     * @dev Compliant with EIP-712: Ethereum typed structured data hashing and signing,
     *      see https://eips.ethereum.org/EIPS/eip-712
     *
     * @dev The procedure of signing the migration with signature request is:
     *      1. Construct the EIP712Domain as per https://eips.ethereum.org/EIPS/eip-712,
     *          version and salt are omitted:
     *          {
     *              name: "TokenLocking",
     *              chainId: await web3.eth.net.getId(),
     *              verifyingContract: <deployed TokenLocking address>
     *          }
     *      2. Construct the EIP712 domainSeparator:
     *          domainSeparator = hashStruct(eip712Domain)
     *      3. Construct the EIP721 TypedData:
     *          primaryType: "Migration",
     *          types: {
     *              Migration: [
     *                  {name: 'from', type: 'address'},
     *                  {name: 'to', type: 'address'},
     *                  {name: 'nonce', type: 'uint256'},
     *                  {name: 'expiry', type: 'uint256'}
     *              ]
     *          }
     *      4. Build the message to sign:
     *          {
     *              from: _from,
     *              to: _to,
     *              nonce: _nonce,
     *              exp: _exp
     *          }
     *       5. Build the structHash as per EIP712 and sign it
     *          (see example https://github.com/ethereum/EIPs/blob/master/assets/eip-712/Example.js)
     *
     * @dev Refer to EIP712 code examples:
     *      https://github.com/ethereum/EIPs/blob/master/assets/eip-712/Example.sol
     *      https://github.com/ethereum/EIPs/blob/master/assets/eip-712/Example.js
     *
     * @dev See TokenLocking-ns.test.js for the exact working examples with TokenLocking.sol
     *
     * @param _from an address to move locked tokens from
     * @param _to an address to move locked tokens to
     * @param _nonce nonce used to construct the signature, and used to validate it;
     *      nonce is increased by one after successful signature validation and vote delegation
     * @param _exp signature expiration time
     * @param v the recovery byte of the signature
     * @param r half of the ECDSA signature pair
     * @param s half of the ECDSA signature pair
     */
    function migrateWithSig(
        address _from,
        address _to,
        uint256 _nonce,
        uint256 _exp,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public {
        // build the EIP-712 hashStruct of the delegation message
        bytes32 hashStruct = keccak256(abi.encode(MIGRATION_TYPEHASH, _from, _to, _nonce, _exp));

        // calculate the EIP-712 digest "\x19\x01" ‖ domainSeparator ‖ hashStruct(message)
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR, hashStruct));

        // recover the address who signed the message with v, r, s
        address signer = ecrecover(digest, v, r, s);

        // perform message integrity and security validations
        require(signer != address(0), "invalid signature");
        require(_nonce == migrationNonces[signer], "invalid nonce");
        require(now256() < _exp, "signature expired");

        // verify signature: it should be either token owner or contract owner
        require(
            (signer == _from && msg.sender == owner()) || (signer == owner() && msg.sender == _from),
            "access denied"
        );

        // update the nonce for that particular signer to avoid replay attack
        migrationNonces[signer]++;

        // delegate call to `__migrateTokens` - execute the logic required
        __migrateTokens(_from, _to);
    }

    /**
     * @dev Moves locked tokens from `_from` address to `_to` address
     * @dev Designed to be used in emergency situations when locked token
     *      holder suspects their account credentials ware revealed
     *
     * @param _from an address to move locked tokens from
     * @param _to an address to move locked tokens to
     */
    function __migrateTokens(address _from, address _to) private {
        // verify `_to` is set
        require(_to != address(0), "receiver is not set");

        // following 2 verifications also ensure _to != _from
        // verify `_from` user record exists
        require(userRecords[_from].ilvBalance != 0 || userRecords[_from].ilvReleased != 0, "sender doesn't exist");
        // verify `_to` user record doesn't exist
        require(userRecords[_to].ilvBalance == 0 && userRecords[_to].ilvReleased == 0, "recipient already exists");

        // move user record from `_from` to `_to`
        userRecords[_to] = userRecords[_from];
        // delete old user record
        delete userRecords[_from];

        // if locking pool is defined
        if (address(pool) != address(0)) {
            // register this change within the pool
            pool.changeLockedHolder(_from, _to);
        }

        // push new locked holder into locked holders array
        lockedHolders.push(_to);
        // note: we do not delete old locked holder from the array since by design old account
        // is treated as a compromised one and should not be used, meaning it is always safe to erase it

        // emit an event
        emit TokensMigrated(_from, _to);
    }

    /**
     * @notice Calculates token amount available for holder to be released
     *
     * @param holder an address to query releasable amount for
     * @return ilvAmt amount of ILV tokens available for withdrawal (see release function)
     */
    function releasableAmount(address holder) public view returns (uint96 ilvAmt) {
        // calculate a difference between amount of tokens available for
        // withdrawal currently (vested amount) and amount of tokens already withdrawn (released)
        return vestedAmount(holder) - userRecords[holder].ilvReleased;
    }

    /**
     * @notice Calculates the amount to be unlocked for the given holder at the
     *      current moment in time (vested amount)
     *
     * @dev This function implements the linear unlocking mechanism based on
     *      the `cliff` and `duration` global variables as parameters:
     *      amount is zero before `cliff`, then linearly increases during `duration` period,
     *      and reaches the total holder's locked balance after that
     *
     * @dev See `linearUnlockAmt()` function for linear unlocking internals
     *
     * @param holder an address to query unlocked (vested) amount for
     * @return ilvAmt amount of ILV tokens to be unlocked based on the holder's locked balance and current time,
     *      the value is zero before `cliff`, then linearly increases during `duration` period,
     *      and reaches the total holder's locked balance after that
     */
    function vestedAmount(address holder) public view returns (uint96 ilvAmt) {
        // before `cliff` we don't need to access the storage:
        if (now256() < cliff) {
            // the return values are zeros
            return 0;
        }

        // read user record values into the memory
        UserRecord memory userRecord = userRecords[holder];

        // the value is calculated as a linear function of time
        ilvAmt = linearUnlockAmt(userRecord.ilvBalance + userRecord.ilvReleased);

        // return the result is unnecessary, but we stick to the single code style
        return ilvAmt;
    }

    /**
     * @notice Linear unlocking function of time, expects balance as an input,
     *      uses current time, `cliff` and `duration` set in the smart contract state vars
     *
     * @param balance value to calculate linear unlocking fraction for
     * @return linear unlocking fraction; zero before `cliff`, `balance` after `cliff + duration`
     */
    function linearUnlockAmt(uint96 balance) public view returns (uint96) {
        // read current time value
        uint256 _now256 = now256();

        // and fit it into the safe bounds [cliff, cliff + duration] to be used in linear unlocking function
        if (_now256 < cliff) {
            _now256 = cliff;
        } else if (_now256 - cliff > duration) {
            _now256 = cliff + duration;
        }

        // the value is calculated as a linear function of time
        return uint96((balance * (_now256 - cliff)) / duration);
    }

    /**
     * @dev Testing time-dependent functionality is difficult and the best way of
     *      doing it is to override time in helper test smart contracts
     *
     * @return `block.timestamp` in mainnet, custom values in testnets (if overridden)
     */
    function now256() public view virtual returns (uint256) {
        // return current block timestamp
        return block.timestamp;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;

/**
 * @title ERC20 token receiver interface
 *
 * @dev Interface for any contract that wants to support safe transfers
 *      from ERC20 token smart contracts.
 * @dev Inspired by ERC721 and ERC223 token standards
 *
 * @dev See https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
 * @dev See https://github.com/ethereum/EIPs/issues/223
 *
 * @author Basil Gorin
 */
interface ERC20Receiver {
  /**
   * @notice Handle the receipt of a ERC20 token(s)
   * @dev The ERC20 smart contract calls this function on the recipient
   *      after a successful transfer (`safeTransferFrom`).
   *      This function MAY throw to revert and reject the transfer.
   *      Return of other than the magic value MUST result in the transaction being reverted.
   * @notice The contract address is always the message sender.
   *      A wallet/broker/auction application MUST implement the wallet interface
   *      if it will accept safe transfers.
   * @param _operator The address which called `safeTransferFrom` function
   * @param _from The address which previously owned the token
   * @param _value amount of tokens which is being transferred
   * @param _data additional data with no specified format
   * @return `bytes4(keccak256("onERC20Received(address,address,uint256,bytes)"))` unless throwing
   */
  function onERC20Received(address _operator, address _from, uint256 _value, bytes calldata _data) external returns(bytes4);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;

import "../utils/AddressUtils.sol";
import "../utils/AccessControl.sol";
import "./ERC20Receiver.sol";

/**
 * @title Illuvium (ILV) ERC20 token
 *
 * @notice Illuvium is a core ERC20 token powering the game.
 *      It serves as an in-game currency, is tradable on exchanges,
 *      it powers up the governance protocol (Illuvium DAO) and participates in Yield Farming.
 *
 * @dev Token Summary:
 *      - Symbol: ILV
 *      - Name: Illuvium
 *      - Decimals: 18
 *      - Initial token supply: 7,000,000 ILV
 *      - Maximum final token supply: 10,000,000 ILV
 *          - Up to 3,000,000 ILV may get minted in 3 years period via yield farming
 *      - Mintable: total supply may increase
 *      - Burnable: total supply may decrease
 *
 * @dev Token balances and total supply are effectively 192 bits long, meaning that maximum
 *      possible total supply smart contract is able to track is 2^192 (close to 10^40 tokens)
 *
 * @dev Smart contract doesn't use safe math. All arithmetic operations are overflow/underflow safe.
 *      Additionally, Solidity 0.8.1 enforces overflow/underflow safety.
 *
 * @dev ERC20: reviewed according to https://eips.ethereum.org/EIPS/eip-20
 *
 * @dev ERC20: contract has passed OpenZeppelin ERC20 tests,
 *      see https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/test/token/ERC20/ERC20.behavior.js
 *      see https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/test/token/ERC20/ERC20.test.js
 *      see adopted copies of these tests in the `test` folder
 *
 * @dev ERC223/ERC777: not supported;
 *      send tokens via `safeTransferFrom` and implement `ERC20Receiver.onERC20Received` on the receiver instead
 *
 * @dev Multiple Withdrawal Attack on ERC20 Tokens (ISBN:978-1-7281-3027-9) - resolved
 *      Related events and functions are marked with "ISBN:978-1-7281-3027-9" tag:
 *        - event Transferred(address indexed _by, address indexed _from, address indexed _to, uint256 _value)
 *        - event Approved(address indexed _owner, address indexed _spender, uint256 _oldValue, uint256 _value)
 *        - function increaseAllowance(address _spender, uint256 _value) public returns (bool)
 *        - function decreaseAllowance(address _spender, uint256 _value) public returns (bool)
 *      See: https://ieeexplore.ieee.org/document/8802438
 *      See: https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
 *
 * @author Basil Gorin
 */
contract IlluviumERC20 is AccessControl {
  /**
   * @dev Smart contract unique identifier, a random number
   * @dev Should be regenerated each time smart contact source code is changed
   *      and changes smart contract itself is to be redeployed
   * @dev Generated using https://www.random.org/bytes/
   */
  uint256 public constant TOKEN_UID = 0x83ecb176af7c4f35a45ff0018282e3a05a1018065da866182df12285866f5a2c;

  /**
   * @notice Name of the token: Illuvium
   *
   * @notice ERC20 name of the token (long name)
   *
   * @dev ERC20 `function name() public view returns (string)`
   *
   * @dev Field is declared public: getter name() is created when compiled,
   *      it returns the name of the token.
   */
  string public constant name = "Illuvium";

  /**
   * @notice Symbol of the token: ILV
   *
   * @notice ERC20 symbol of that token (short name)
   *
   * @dev ERC20 `function symbol() public view returns (string)`
   *
   * @dev Field is declared public: getter symbol() is created when compiled,
   *      it returns the symbol of the token
   */
  string public constant symbol = "ILV";

  /**
   * @notice Decimals of the token: 18
   *
   * @dev ERC20 `function decimals() public view returns (uint8)`
   *
   * @dev Field is declared public: getter decimals() is created when compiled,
   *      it returns the number of decimals used to get its user representation.
   *      For example, if `decimals` equals `6`, a balance of `1,500,000` tokens should
   *      be displayed to a user as `1,5` (`1,500,000 / 10 ** 6`).
   *
   * @dev NOTE: This information is only used for _display_ purposes: it in
   *      no way affects any of the arithmetic of the contract, including balanceOf() and transfer().
   */
  uint8 public constant decimals = 18;

  /**
   * @notice Total supply of the token: initially 7,000,000,
   *      with the potential to grow up to 10,000,000 during yield farming period (3 years)
   *
   * @dev ERC20 `function totalSupply() public view returns (uint256)`
   *
   * @dev Field is declared public: getter totalSupply() is created when compiled,
   *      it returns the amount of tokens in existence.
   */
  uint256 public totalSupply; // is set to 7 million * 10^18 in the constructor

  /**
   * @dev A record of all the token balances
   * @dev This mapping keeps record of all token owners:
   *      owner => balance
   */
  mapping(address => uint256) public tokenBalances;

  /**
   * @notice A record of each account's voting delegate
   *
   * @dev Auxiliary data structure used to sum up an account's voting power
   *
   * @dev This mapping keeps record of all voting power delegations:
   *      voting delegator (token owner) => voting delegate
   */
  mapping(address => address) public votingDelegates;

  /**
   * @notice A voting power record binds voting power of a delegate to a particular
   *      block when the voting power delegation change happened
   */
  struct VotingPowerRecord {
    /*
     * @dev block.number when delegation has changed; starting from
     *      that block voting power value is in effect
     */
    uint64 blockNumber;

    /*
     * @dev cumulative voting power a delegate has obtained starting
     *      from the block stored in blockNumber
     */
    uint192 votingPower;
  }

  /**
   * @notice A record of each account's voting power
   *
   * @dev Primarily data structure to store voting power for each account.
   *      Voting power sums up from the account's token balance and delegated
   *      balances.
   *
   * @dev Stores current value and entire history of its changes.
   *      The changes are stored as an array of checkpoints.
   *      Checkpoint is an auxiliary data structure containing voting
   *      power (number of votes) and block number when the checkpoint is saved
   *
   * @dev Maps voting delegate => voting power record
   */
  mapping(address => VotingPowerRecord[]) public votingPowerHistory;

  /**
   * @dev A record of nonces for signing/validating signatures in `delegateWithSig`
   *      for every delegate, increases after successful validation
   *
   * @dev Maps delegate address => delegate nonce
   */
  mapping(address => uint256) public nonces;

  /**
   * @notice A record of all the allowances to spend tokens on behalf
   * @dev Maps token owner address to an address approved to spend
   *      some tokens on behalf, maps approved address to that amount
   * @dev owner => spender => value
   */
  mapping(address => mapping(address => uint256)) public transferAllowances;

  /**
   * @notice Enables ERC20 transfers of the tokens
   *      (transfer by the token owner himself)
   * @dev Feature FEATURE_TRANSFERS must be enabled in order for
   *      `transfer()` function to succeed
   */
  uint32 public constant FEATURE_TRANSFERS = 0x0000_0001;

  /**
   * @notice Enables ERC20 transfers on behalf
   *      (transfer by someone else on behalf of token owner)
   * @dev Feature FEATURE_TRANSFERS_ON_BEHALF must be enabled in order for
   *      `transferFrom()` function to succeed
   * @dev Token owner must call `approve()` first to authorize
   *      the transfer on behalf
   */
  uint32 public constant FEATURE_TRANSFERS_ON_BEHALF = 0x0000_0002;

  /**
   * @dev Defines if the default behavior of `transfer` and `transferFrom`
   *      checks if the receiver smart contract supports ERC20 tokens
   * @dev When feature FEATURE_UNSAFE_TRANSFERS is enabled the transfers do not
   *      check if the receiver smart contract supports ERC20 tokens,
   *      i.e. `transfer` and `transferFrom` behave like `unsafeTransferFrom`
   * @dev When feature FEATURE_UNSAFE_TRANSFERS is disabled (default) the transfers
   *      check if the receiver smart contract supports ERC20 tokens,
   *      i.e. `transfer` and `transferFrom` behave like `safeTransferFrom`
   */
  uint32 public constant FEATURE_UNSAFE_TRANSFERS = 0x0000_0004;

  /**
   * @notice Enables token owners to burn their own tokens,
   *      including locked tokens which are burnt first
   * @dev Feature FEATURE_OWN_BURNS must be enabled in order for
   *      `burn()` function to succeed when called by token owner
   */
  uint32 public constant FEATURE_OWN_BURNS = 0x0000_0008;

  /**
   * @notice Enables approved operators to burn tokens on behalf of their owners,
   *      including locked tokens which are burnt first
   * @dev Feature FEATURE_OWN_BURNS must be enabled in order for
   *      `burn()` function to succeed when called by approved operator
   */
  uint32 public constant FEATURE_BURNS_ON_BEHALF = 0x0000_0010;

  /**
   * @notice Enables delegators to elect delegates
   * @dev Feature FEATURE_DELEGATIONS must be enabled in order for
   *      `delegate()` function to succeed
   */
  uint32 public constant FEATURE_DELEGATIONS = 0x0000_0020;

  /**
   * @notice Enables delegators to elect delegates on behalf
   *      (via an EIP712 signature)
   * @dev Feature FEATURE_DELEGATIONS must be enabled in order for
   *      `delegateWithSig()` function to succeed
   */
  uint32 public constant FEATURE_DELEGATIONS_ON_BEHALF = 0x0000_0040;

  /**
   * @notice Token creator is responsible for creating (minting)
   *      tokens to an arbitrary address
   * @dev Role ROLE_TOKEN_CREATOR allows minting tokens
   *      (calling `mint` function)
   */
  uint32 public constant ROLE_TOKEN_CREATOR = 0x0001_0000;

  /**
   * @notice Token destroyer is responsible for destroying (burning)
   *      tokens owned by an arbitrary address
   * @dev Role ROLE_TOKEN_DESTROYER allows burning tokens
   *      (calling `burn` function)
   */
  uint32 public constant ROLE_TOKEN_DESTROYER = 0x0002_0000;

  /**
   * @notice ERC20 receivers are allowed to receive tokens without ERC20 safety checks,
   *      which may be useful to simplify tokens transfers into "legacy" smart contracts
   * @dev When `FEATURE_UNSAFE_TRANSFERS` is not enabled addresses having
   *      `ROLE_ERC20_RECEIVER` permission are allowed to receive tokens
   *      via `transfer` and `transferFrom` functions in the same way they
   *      would via `unsafeTransferFrom` function
   * @dev When `FEATURE_UNSAFE_TRANSFERS` is enabled `ROLE_ERC20_RECEIVER` permission
   *      doesn't affect the transfer behaviour since
   *      `transfer` and `transferFrom` behave like `unsafeTransferFrom` for any receiver
   * @dev ROLE_ERC20_RECEIVER is a shortening for ROLE_UNSAFE_ERC20_RECEIVER
   */
  uint32 public constant ROLE_ERC20_RECEIVER = 0x0004_0000;

  /**
   * @notice ERC20 senders are allowed to send tokens without ERC20 safety checks,
   *      which may be useful to simplify tokens transfers into "legacy" smart contracts
   * @dev When `FEATURE_UNSAFE_TRANSFERS` is not enabled senders having
   *      `ROLE_ERC20_SENDER` permission are allowed to send tokens
   *      via `transfer` and `transferFrom` functions in the same way they
   *      would via `unsafeTransferFrom` function
   * @dev When `FEATURE_UNSAFE_TRANSFERS` is enabled `ROLE_ERC20_SENDER` permission
   *      doesn't affect the transfer behaviour since
   *      `transfer` and `transferFrom` behave like `unsafeTransferFrom` for any receiver
   * @dev ROLE_ERC20_SENDER is a shortening for ROLE_UNSAFE_ERC20_SENDER
   */
  uint32 public constant ROLE_ERC20_SENDER = 0x0008_0000;

  /**
   * @dev Magic value to be returned by ERC20Receiver upon successful reception of token(s)
   * @dev Equal to `bytes4(keccak256("onERC20Received(address,address,uint256,bytes)"))`,
   *      which can be also obtained as `ERC20Receiver(address(0)).onERC20Received.selector`
   */
  bytes4 private constant ERC20_RECEIVED = 0x4fc35859;

  /**
   * @notice EIP-712 contract's domain typeHash, see https://eips.ethereum.org/EIPS/eip-712#rationale-for-typehash
   */
  bytes32 public constant DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,uint256 chainId,address verifyingContract)");

  /**
   * @notice EIP-712 delegation struct typeHash, see https://eips.ethereum.org/EIPS/eip-712#rationale-for-typehash
   */
  bytes32 public constant DELEGATION_TYPEHASH = keccak256("Delegation(address delegate,uint256 nonce,uint256 expiry)");

  /**
   * @dev Fired in transfer(), transferFrom() and some other (non-ERC20) functions
   *
   * @dev ERC20 `event Transfer(address indexed _from, address indexed _to, uint256 _value)`
   *
   * @param _from an address tokens were consumed from
   * @param _to an address tokens were sent to
   * @param _value number of tokens transferred
   */
  event Transfer(address indexed _from, address indexed _to, uint256 _value);

  /**
   * @dev Fired in approve() and approveAtomic() functions
   *
   * @dev ERC20 `event Approval(address indexed _owner, address indexed _spender, uint256 _value)`
   *
   * @param _owner an address which granted a permission to transfer
   *      tokens on its behalf
   * @param _spender an address which received a permission to transfer
   *      tokens on behalf of the owner `_owner`
   * @param _value amount of tokens granted to transfer on behalf
   */
  event Approval(address indexed _owner, address indexed _spender, uint256 _value);

  /**
   * @dev Fired in mint() function
   *
   * @param _by an address which minted some tokens (transaction sender)
   * @param _to an address the tokens were minted to
   * @param _value an amount of tokens minted
   */
  event Minted(address indexed _by, address indexed _to, uint256 _value);

  /**
   * @dev Fired in burn() function
   *
   * @param _by an address which burned some tokens (transaction sender)
   * @param _from an address the tokens were burnt from
   * @param _value an amount of tokens burnt
   */
  event Burnt(address indexed _by, address indexed _from, uint256 _value);

  /**
   * @dev Resolution for the Multiple Withdrawal Attack on ERC20 Tokens (ISBN:978-1-7281-3027-9)
   *
   * @dev Similar to ERC20 Transfer event, but also logs an address which executed transfer
   *
   * @dev Fired in transfer(), transferFrom() and some other (non-ERC20) functions
   *
   * @param _by an address which performed the transfer
   * @param _from an address tokens were consumed from
   * @param _to an address tokens were sent to
   * @param _value number of tokens transferred
   */
  event Transferred(address indexed _by, address indexed _from, address indexed _to, uint256 _value);

  /**
   * @dev Resolution for the Multiple Withdrawal Attack on ERC20 Tokens (ISBN:978-1-7281-3027-9)
   *
   * @dev Similar to ERC20 Approve event, but also logs old approval value
   *
   * @dev Fired in approve() and approveAtomic() functions
   *
   * @param _owner an address which granted a permission to transfer
   *      tokens on its behalf
   * @param _spender an address which received a permission to transfer
   *      tokens on behalf of the owner `_owner`
   * @param _oldValue previously granted amount of tokens to transfer on behalf
   * @param _value new granted amount of tokens to transfer on behalf
   */
  event Approved(address indexed _owner, address indexed _spender, uint256 _oldValue, uint256 _value);

  /**
   * @dev Notifies that a key-value pair in `votingDelegates` mapping has changed,
   *      i.e. a delegator address has changed its delegate address
   *
   * @param _of delegator address, a token owner
   * @param _from old delegate, an address which delegate right is revoked
   * @param _to new delegate, an address which received the voting power
   */
  event DelegateChanged(address indexed _of, address indexed _from, address indexed _to);

  /**
   * @dev Notifies that a key-value pair in `votingPowerHistory` mapping has changed,
   *      i.e. a delegate's voting power has changed.
   *
   * @param _of delegate whose voting power has changed
   * @param _fromVal previous number of votes delegate had
   * @param _toVal new number of votes delegate has
   */
  event VotingPowerChanged(address indexed _of, uint256 _fromVal, uint256 _toVal);

  /**
   * @dev Deploys the token smart contract,
   *      assigns initial token supply to the address specified
   *
   * @param _initialHolder owner of the initial token supply
   */
  constructor(address _initialHolder) {
    // verify initial holder address non-zero (is set)
    require(_initialHolder != address(0), "_initialHolder not set (zero address)");

    // mint initial supply
    mint(_initialHolder, 7_000_000e18);
  }

  // ===== Start: ERC20/ERC223/ERC777 functions =====

  /**
   * @notice Gets the balance of a particular address
   *
   * @dev ERC20 `function balanceOf(address _owner) public view returns (uint256 balance)`
   *
   * @param _owner the address to query the the balance for
   * @return balance an amount of tokens owned by the address specified
   */
  function balanceOf(address _owner) public view returns (uint256 balance) {
    // read the balance and return
    return tokenBalances[_owner];
  }

  /**
   * @notice Transfers some tokens to an external address or a smart contract
   *
   * @dev ERC20 `function transfer(address _to, uint256 _value) public returns (bool success)`
   *
   * @dev Called by token owner (an address which has a
   *      positive token balance tracked by this smart contract)
   * @dev Throws on any error like
   *      * insufficient token balance or
   *      * incorrect `_to` address:
   *          * zero address or
   *          * self address or
   *          * smart contract which doesn't support ERC20
   *
   * @param _to an address to transfer tokens to,
   *      must be either an external address or a smart contract,
   *      compliant with the ERC20 standard
   * @param _value amount of tokens to be transferred, must
   *      be greater than zero
   * @return success true on success, throws otherwise
   */
  function transfer(address _to, uint256 _value) public returns (bool success) {
    // just delegate call to `transferFrom`,
    // `FEATURE_TRANSFERS` is verified inside it
    return transferFrom(msg.sender, _to, _value);
  }

  /**
   * @notice Transfers some tokens on behalf of address `_from' (token owner)
   *      to some other address `_to`
   *
   * @dev ERC20 `function transferFrom(address _from, address _to, uint256 _value) public returns (bool success)`
   *
   * @dev Called by token owner on his own or approved address,
   *      an address approved earlier by token owner to
   *      transfer some amount of tokens on its behalf
   * @dev Throws on any error like
   *      * insufficient token balance or
   *      * incorrect `_to` address:
   *          * zero address or
   *          * same as `_from` address (self transfer)
   *          * smart contract which doesn't support ERC20
   *
   * @param _from token owner which approved caller (transaction sender)
   *      to transfer `_value` of tokens on its behalf
   * @param _to an address to transfer tokens to,
   *      must be either an external address or a smart contract,
   *      compliant with the ERC20 standard
   * @param _value amount of tokens to be transferred, must
   *      be greater than zero
   * @return success true on success, throws otherwise
   */
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
    // depending on `FEATURE_UNSAFE_TRANSFERS` we execute either safe (default)
    // or unsafe transfer
    // if `FEATURE_UNSAFE_TRANSFERS` is enabled
    // or receiver has `ROLE_ERC20_RECEIVER` permission
    // or sender has `ROLE_ERC20_SENDER` permission
    if(isFeatureEnabled(FEATURE_UNSAFE_TRANSFERS)
      || isOperatorInRole(_to, ROLE_ERC20_RECEIVER)
      || isSenderInRole(ROLE_ERC20_SENDER)) {
      // we execute unsafe transfer - delegate call to `unsafeTransferFrom`,
      // `FEATURE_TRANSFERS` is verified inside it
      unsafeTransferFrom(_from, _to, _value);
    }
    // otherwise - if `FEATURE_UNSAFE_TRANSFERS` is disabled
    // and receiver doesn't have `ROLE_ERC20_RECEIVER` permission
    else {
      // we execute safe transfer - delegate call to `safeTransferFrom`, passing empty `_data`,
      // `FEATURE_TRANSFERS` is verified inside it
      safeTransferFrom(_from, _to, _value, "");
    }

    // both `unsafeTransferFrom` and `safeTransferFrom` throw on any error, so
    // if we're here - it means operation successful,
    // just return true
    return true;
  }

  /**
   * @notice Transfers some tokens on behalf of address `_from' (token owner)
   *      to some other address `_to`
   *
   * @dev Inspired by ERC721 safeTransferFrom, this function allows to
   *      send arbitrary data to the receiver on successful token transfer
   * @dev Called by token owner on his own or approved address,
   *      an address approved earlier by token owner to
   *      transfer some amount of tokens on its behalf
   * @dev Throws on any error like
   *      * insufficient token balance or
   *      * incorrect `_to` address:
   *          * zero address or
   *          * same as `_from` address (self transfer)
   *          * smart contract which doesn't support ERC20Receiver interface
   * @dev Returns silently on success, throws otherwise
   *
   * @param _from token owner which approved caller (transaction sender)
   *      to transfer `_value` of tokens on its behalf
   * @param _to an address to transfer tokens to,
   *      must be either an external address or a smart contract,
   *      compliant with the ERC20 standard
   * @param _value amount of tokens to be transferred, must
   *      be greater than zero
   * @param _data [optional] additional data with no specified format,
   *      sent in onERC20Received call to `_to` in case if its a smart contract
   */
  function safeTransferFrom(address _from, address _to, uint256 _value, bytes memory _data) public {
    // first delegate call to `unsafeTransferFrom`
    // to perform the unsafe token(s) transfer
    unsafeTransferFrom(_from, _to, _value);

    // after the successful transfer - check if receiver supports
    // ERC20Receiver and execute a callback handler `onERC20Received`,
    // reverting whole transaction on any error:
    // check if receiver `_to` supports ERC20Receiver interface
    if(AddressUtils.isContract(_to)) {
      // if `_to` is a contract - execute onERC20Received
      bytes4 response = ERC20Receiver(_to).onERC20Received(msg.sender, _from, _value, _data);

      // expected response is ERC20_RECEIVED
      require(response == ERC20_RECEIVED, "invalid onERC20Received response");
    }
  }

  /**
   * @notice Transfers some tokens on behalf of address `_from' (token owner)
   *      to some other address `_to`
   *
   * @dev In contrast to `safeTransferFrom` doesn't check recipient
   *      smart contract to support ERC20 tokens (ERC20Receiver)
   * @dev Designed to be used by developers when the receiver is known
   *      to support ERC20 tokens but doesn't implement ERC20Receiver interface
   * @dev Called by token owner on his own or approved address,
   *      an address approved earlier by token owner to
   *      transfer some amount of tokens on its behalf
   * @dev Throws on any error like
   *      * insufficient token balance or
   *      * incorrect `_to` address:
   *          * zero address or
   *          * same as `_from` address (self transfer)
   * @dev Returns silently on success, throws otherwise
   *
   * @param _from token owner which approved caller (transaction sender)
   *      to transfer `_value` of tokens on its behalf
   * @param _to an address to transfer tokens to,
   *      must be either an external address or a smart contract,
   *      compliant with the ERC20 standard
   * @param _value amount of tokens to be transferred, must
   *      be greater than zero
   */
  function unsafeTransferFrom(address _from, address _to, uint256 _value) public {
    // if `_from` is equal to sender, require transfers feature to be enabled
    // otherwise require transfers on behalf feature to be enabled
    require(_from == msg.sender && isFeatureEnabled(FEATURE_TRANSFERS)
         || _from != msg.sender && isFeatureEnabled(FEATURE_TRANSFERS_ON_BEHALF),
            _from == msg.sender? "transfers are disabled": "transfers on behalf are disabled");

    // non-zero source address check - Zeppelin
    // obviously, zero source address is a client mistake
    // it's not part of ERC20 standard but it's reasonable to fail fast
    // since for zero value transfer transaction succeeds otherwise
    require(_from != address(0), "ERC20: transfer from the zero address"); // Zeppelin msg

    // non-zero recipient address check
    require(_to != address(0), "ERC20: transfer to the zero address"); // Zeppelin msg

    // sender and recipient cannot be the same
    require(_from != _to, "sender and recipient are the same (_from = _to)");

    // sending tokens to the token smart contract itself is a client mistake
    require(_to != address(this), "invalid recipient (transfer to the token smart contract itself)");

    // according to ERC-20 Token Standard, https://eips.ethereum.org/EIPS/eip-20
    // "Transfers of 0 values MUST be treated as normal transfers and fire the Transfer event."
    if(_value == 0) {
      // emit an ERC20 transfer event
      emit Transfer(_from, _to, _value);

      // don't forget to return - we're done
      return;
    }

    // no need to make arithmetic overflow check on the _value - by design of mint()

    // in case of transfer on behalf
    if(_from != msg.sender) {
      // read allowance value - the amount of tokens allowed to transfer - into the stack
      uint256 _allowance = transferAllowances[_from][msg.sender];

      // verify sender has an allowance to transfer amount of tokens requested
      require(_allowance >= _value, "ERC20: transfer amount exceeds allowance"); // Zeppelin msg

      // update allowance value on the stack
      _allowance -= _value;

      // update the allowance value in storage
      transferAllowances[_from][msg.sender] = _allowance;

      // emit an improved atomic approve event
      emit Approved(_from, msg.sender, _allowance + _value, _allowance);

      // emit an ERC20 approval event to reflect the decrease
      emit Approval(_from, msg.sender, _allowance);
    }

    // verify sender has enough tokens to transfer on behalf
    require(tokenBalances[_from] >= _value, "ERC20: transfer amount exceeds balance"); // Zeppelin msg

    // perform the transfer:
    // decrease token owner (sender) balance
    tokenBalances[_from] -= _value;

    // increase `_to` address (receiver) balance
    tokenBalances[_to] += _value;

    // move voting power associated with the tokens transferred
    __moveVotingPower(votingDelegates[_from], votingDelegates[_to], _value);

    // emit an improved transfer event
    emit Transferred(msg.sender, _from, _to, _value);

    // emit an ERC20 transfer event
    emit Transfer(_from, _to, _value);
  }

  /**
   * @notice Approves address called `_spender` to transfer some amount
   *      of tokens on behalf of the owner
   *
   * @dev ERC20 `function approve(address _spender, uint256 _value) public returns (bool success)`
   *
   * @dev Caller must not necessarily own any tokens to grant the permission
   *
   * @param _spender an address approved by the caller (token owner)
   *      to spend some tokens on its behalf
   * @param _value an amount of tokens spender `_spender` is allowed to
   *      transfer on behalf of the token owner
   * @return success true on success, throws otherwise
   */
  function approve(address _spender, uint256 _value) public returns (bool success) {
    // non-zero spender address check - Zeppelin
    // obviously, zero spender address is a client mistake
    // it's not part of ERC20 standard but it's reasonable to fail fast
    require(_spender != address(0), "ERC20: approve to the zero address"); // Zeppelin msg

    // read old approval value to emmit an improved event (ISBN:978-1-7281-3027-9)
    uint256 _oldValue = transferAllowances[msg.sender][_spender];

    // perform an operation: write value requested into the storage
    transferAllowances[msg.sender][_spender] = _value;

    // emit an improved atomic approve event (ISBN:978-1-7281-3027-9)
    emit Approved(msg.sender, _spender, _oldValue, _value);

    // emit an ERC20 approval event
    emit Approval(msg.sender, _spender, _value);

    // operation successful, return true
    return true;
  }

  /**
   * @notice Returns the amount which _spender is still allowed to withdraw from _owner.
   *
   * @dev ERC20 `function allowance(address _owner, address _spender) public view returns (uint256 remaining)`
   *
   * @dev A function to check an amount of tokens owner approved
   *      to transfer on its behalf by some other address called "spender"
   *
   * @param _owner an address which approves transferring some tokens on its behalf
   * @param _spender an address approved to transfer some tokens on behalf
   * @return remaining an amount of tokens approved address `_spender` can transfer on behalf
   *      of token owner `_owner`
   */
  function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
    // read the value from storage and return
    return transferAllowances[_owner][_spender];
  }

  // ===== End: ERC20/ERC223/ERC777 functions =====

  // ===== Start: Resolution for the Multiple Withdrawal Attack on ERC20 Tokens (ISBN:978-1-7281-3027-9) =====

  /**
   * @notice Increases the allowance granted to `spender` by the transaction sender
   *
   * @dev Resolution for the Multiple Withdrawal Attack on ERC20 Tokens (ISBN:978-1-7281-3027-9)
   *
   * @dev Throws if value to increase by is zero or too big and causes arithmetic overflow
   *
   * @param _spender an address approved by the caller (token owner)
   *      to spend some tokens on its behalf
   * @param _value an amount of tokens to increase by
   * @return success true on success, throws otherwise
   */
  function increaseAllowance(address _spender, uint256 _value) public virtual returns (bool) {
    // read current allowance value
    uint256 currentVal = transferAllowances[msg.sender][_spender];

    // non-zero _value and arithmetic overflow check on the allowance
    require(currentVal + _value > currentVal, "zero value approval increase or arithmetic overflow");

    // delegate call to `approve` with the new value
    return approve(_spender, currentVal + _value);
  }

  /**
   * @notice Decreases the allowance granted to `spender` by the caller.
   *
   * @dev Resolution for the Multiple Withdrawal Attack on ERC20 Tokens (ISBN:978-1-7281-3027-9)
   *
   * @dev Throws if value to decrease by is zero or is bigger than currently allowed value
   *
   * @param _spender an address approved by the caller (token owner)
   *      to spend some tokens on its behalf
   * @param _value an amount of tokens to decrease by
   * @return success true on success, throws otherwise
   */
  function decreaseAllowance(address _spender, uint256 _value) public virtual returns (bool) {
    // read current allowance value
    uint256 currentVal = transferAllowances[msg.sender][_spender];

    // non-zero _value check on the allowance
    require(_value > 0, "zero value approval decrease");

    // verify allowance decrease doesn't underflow
    require(currentVal >= _value, "ERC20: decreased allowance below zero");

    // delegate call to `approve` with the new value
    return approve(_spender, currentVal - _value);
  }

  // ===== End: Resolution for the Multiple Withdrawal Attack on ERC20 Tokens (ISBN:978-1-7281-3027-9) =====

  // ===== Start: Minting/burning extension =====

  /**
   * @dev Mints (creates) some tokens to address specified
   * @dev The value specified is treated as is without taking
   *      into account what `decimals` value is
   * @dev Behaves effectively as `mintTo` function, allowing
   *      to specify an address to mint tokens to
   * @dev Requires sender to have `ROLE_TOKEN_CREATOR` permission
   *
   * @dev Throws on overflow, if totalSupply + _value doesn't fit into uint256
   *
   * @param _to an address to mint tokens to
   * @param _value an amount of tokens to mint (create)
   */
  function mint(address _to, uint256 _value) public {
    // check if caller has sufficient permissions to mint tokens
    require(isSenderInRole(ROLE_TOKEN_CREATOR), "insufficient privileges (ROLE_TOKEN_CREATOR required)");

    // non-zero recipient address check
    require(_to != address(0), "ERC20: mint to the zero address"); // Zeppelin msg

    // non-zero _value and arithmetic overflow check on the total supply
    // this check automatically secures arithmetic overflow on the individual balance
    require(totalSupply + _value > totalSupply, "zero value mint or arithmetic overflow");

    // uint192 overflow check (required by voting delegation)
    require(totalSupply + _value <= type(uint192).max, "total supply overflow (uint192)");

    // perform mint:
    // increase total amount of tokens value
    totalSupply += _value;

    // increase `_to` address balance
    tokenBalances[_to] += _value;

    // create voting power associated with the tokens minted
    __moveVotingPower(address(0), votingDelegates[_to], _value);

    // fire a minted event
    emit Minted(msg.sender, _to, _value);

    // emit an improved transfer event
    emit Transferred(msg.sender, address(0), _to, _value);

    // fire ERC20 compliant transfer event
    emit Transfer(address(0), _to, _value);
  }

  /**
   * @dev Burns (destroys) some tokens from the address specified
   * @dev The value specified is treated as is without taking
   *      into account what `decimals` value is
   * @dev Behaves effectively as `burnFrom` function, allowing
   *      to specify an address to burn tokens from
   * @dev Requires sender to have `ROLE_TOKEN_DESTROYER` permission
   *
   * @param _from an address to burn some tokens from
   * @param _value an amount of tokens to burn (destroy)
   */
  function burn(address _from, uint256 _value) public {
    // check if caller has sufficient permissions to burn tokens
    // and if not - check for possibility to burn own tokens or to burn on behalf
    if(!isSenderInRole(ROLE_TOKEN_DESTROYER)) {
      // if `_from` is equal to sender, require own burns feature to be enabled
      // otherwise require burns on behalf feature to be enabled
      require(_from == msg.sender && isFeatureEnabled(FEATURE_OWN_BURNS)
           || _from != msg.sender && isFeatureEnabled(FEATURE_BURNS_ON_BEHALF),
              _from == msg.sender? "burns are disabled": "burns on behalf are disabled");

      // in case of burn on behalf
      if(_from != msg.sender) {
        // read allowance value - the amount of tokens allowed to be burnt - into the stack
        uint256 _allowance = transferAllowances[_from][msg.sender];

        // verify sender has an allowance to burn amount of tokens requested
        require(_allowance >= _value, "ERC20: burn amount exceeds allowance"); // Zeppelin msg

        // update allowance value on the stack
        _allowance -= _value;

        // update the allowance value in storage
        transferAllowances[_from][msg.sender] = _allowance;

        // emit an improved atomic approve event
        emit Approved(msg.sender, _from, _allowance + _value, _allowance);

        // emit an ERC20 approval event to reflect the decrease
        emit Approval(_from, msg.sender, _allowance);
      }
    }

    // at this point we know that either sender is ROLE_TOKEN_DESTROYER or
    // we burn own tokens or on behalf (in latest case we already checked and updated allowances)
    // we have left to execute balance checks and burning logic itself

    // non-zero burn value check
    require(_value != 0, "zero value burn");

    // non-zero source address check - Zeppelin
    require(_from != address(0), "ERC20: burn from the zero address"); // Zeppelin msg

    // verify `_from` address has enough tokens to destroy
    // (basically this is a arithmetic overflow check)
    require(tokenBalances[_from] >= _value, "ERC20: burn amount exceeds balance"); // Zeppelin msg

    // perform burn:
    // decrease `_from` address balance
    tokenBalances[_from] -= _value;

    // decrease total amount of tokens value
    totalSupply -= _value;

    // destroy voting power associated with the tokens burnt
    __moveVotingPower(votingDelegates[_from], address(0), _value);

    // fire a burnt event
    emit Burnt(msg.sender, _from, _value);

    // emit an improved transfer event
    emit Transferred(msg.sender, _from, address(0), _value);

    // fire ERC20 compliant transfer event
    emit Transfer(_from, address(0), _value);
  }

  // ===== End: Minting/burning extension =====

  // ===== Start: DAO Support (Compound-like voting delegation) =====

  /**
   * @notice Gets current voting power of the account `_of`
   * @param _of the address of account to get voting power of
   * @return current cumulative voting power of the account,
   *      sum of token balances of all its voting delegators
   */
  function getVotingPower(address _of) public view returns (uint256) {
    // get a link to an array of voting power history records for an address specified
    VotingPowerRecord[] storage history = votingPowerHistory[_of];

    // lookup the history and return latest element
    return history.length == 0? 0: history[history.length - 1].votingPower;
  }

  /**
   * @notice Gets past voting power of the account `_of` at some block `_blockNum`
   * @dev Throws if `_blockNum` is not in the past (not the finalized block)
   * @param _of the address of account to get voting power of
   * @param _blockNum block number to get the voting power at
   * @return past cumulative voting power of the account,
   *      sum of token balances of all its voting delegators at block number `_blockNum`
   */
  function getVotingPowerAt(address _of, uint256 _blockNum) public view returns (uint256) {
    // make sure block number is not in the past (not the finalized block)
    require(_blockNum < block.number, "not yet determined"); // Compound msg

    // get a link to an array of voting power history records for an address specified
    VotingPowerRecord[] storage history = votingPowerHistory[_of];

    // if voting power history for the account provided is empty
    if(history.length == 0) {
      // than voting power is zero - return the result
      return 0;
    }

    // check latest voting power history record block number:
    // if history was not updated after the block of interest
    if(history[history.length - 1].blockNumber <= _blockNum) {
      // we're done - return last voting power record
      return getVotingPower(_of);
    }

    // check first voting power history record block number:
    // if history was never updated before the block of interest
    if(history[0].blockNumber > _blockNum) {
      // we're done - voting power at the block num of interest was zero
      return 0;
    }

    // `votingPowerHistory[_of]` is an array ordered by `blockNumber`, ascending;
    // apply binary search on `votingPowerHistory[_of]` to find such an entry number `i`, that
    // `votingPowerHistory[_of][i].blockNumber <= _blockNum`, but in the same time
    // `votingPowerHistory[_of][i + 1].blockNumber > _blockNum`
    // return the result - voting power found at index `i`
    return history[__binaryLookup(_of, _blockNum)].votingPower;
  }

  /**
   * @dev Reads an entire voting power history array for the delegate specified
   *
   * @param _of delegate to query voting power history for
   * @return voting power history array for the delegate of interest
   */
  function getVotingPowerHistory(address _of) public view returns(VotingPowerRecord[] memory) {
    // return an entire array as memory
    return votingPowerHistory[_of];
  }

  /**
   * @dev Returns length of the voting power history array for the delegate specified;
   *      useful since reading an entire array just to get its length is expensive (gas cost)
   *
   * @param _of delegate to query voting power history length for
   * @return voting power history array length for the delegate of interest
   */
  function getVotingPowerHistoryLength(address _of) public view returns(uint256) {
    // read array length and return
    return votingPowerHistory[_of].length;
  }

  /**
   * @notice Delegates voting power of the delegator `msg.sender` to the delegate `_to`
   *
   * @dev Accepts zero value address to delegate voting power to, effectively
   *      removing the delegate in that case
   *
   * @param _to address to delegate voting power to
   */
  function delegate(address _to) public {
    // verify delegations are enabled
    require(isFeatureEnabled(FEATURE_DELEGATIONS), "delegations are disabled");
    // delegate call to `__delegate`
    __delegate(msg.sender, _to);
  }

  /**
   * @notice Delegates voting power of the delegator (represented by its signature) to the delegate `_to`
   *
   * @dev Accepts zero value address to delegate voting power to, effectively
   *      removing the delegate in that case
   *
   * @dev Compliant with EIP-712: Ethereum typed structured data hashing and signing,
   *      see https://eips.ethereum.org/EIPS/eip-712
   *
   * @param _to address to delegate voting power to
   * @param _nonce nonce used to construct the signature, and used to validate it;
   *      nonce is increased by one after successful signature validation and vote delegation
   * @param _exp signature expiration time
   * @param v the recovery byte of the signature
   * @param r half of the ECDSA signature pair
   * @param s half of the ECDSA signature pair
   */
  function delegateWithSig(address _to, uint256 _nonce, uint256 _exp, uint8 v, bytes32 r, bytes32 s) public {
    // verify delegations on behalf are enabled
    require(isFeatureEnabled(FEATURE_DELEGATIONS_ON_BEHALF), "delegations on behalf are disabled");

    // build the EIP-712 contract domain separator
    bytes32 domainSeparator = keccak256(abi.encode(DOMAIN_TYPEHASH, keccak256(bytes(name)), block.chainid, address(this)));

    // build the EIP-712 hashStruct of the delegation message
    bytes32 hashStruct = keccak256(abi.encode(DELEGATION_TYPEHASH, _to, _nonce, _exp));

    // calculate the EIP-712 digest "\x19\x01" ‖ domainSeparator ‖ hashStruct(message)
    bytes32 digest = keccak256(abi.encodePacked("\x19\x01", domainSeparator, hashStruct));

    // recover the address who signed the message with v, r, s
    address signer = ecrecover(digest, v, r, s);

    // perform message integrity and security validations
    require(signer != address(0), "invalid signature"); // Compound msg
    require(_nonce == nonces[signer], "invalid nonce"); // Compound msg
    require(block.timestamp < _exp, "signature expired"); // Compound msg

    // update the nonce for that particular signer to avoid replay attack
    nonces[signer]++;

    // delegate call to `__delegate` - execute the logic required
    __delegate(signer, _to);
  }

  /**
   * @dev Auxiliary function to delegate delegator's `_from` voting power to the delegate `_to`
   * @dev Writes to `votingDelegates` and `votingPowerHistory` mappings
   *
   * @param _from delegator who delegates his voting power
   * @param _to delegate who receives the voting power
   */
  function __delegate(address _from, address _to) private {
    // read current delegate to be replaced by a new one
    address _fromDelegate = votingDelegates[_from];

    // read current voting power (it is equal to token balance)
    uint256 _value = tokenBalances[_from];

    // reassign voting delegate to `_to`
    votingDelegates[_from] = _to;

    // update voting power for `_fromDelegate` and `_to`
    __moveVotingPower(_fromDelegate, _to, _value);

    // emit an event
    emit DelegateChanged(_from, _fromDelegate, _to);
  }

  /**
   * @dev Auxiliary function to move voting power `_value`
   *      from delegate `_from` to the delegate `_to`
   *
   * @dev Doesn't have any effect if `_from == _to`, or if `_value == 0`
   *
   * @param _from delegate to move voting power from
   * @param _to delegate to move voting power to
   * @param _value voting power to move from `_from` to `_to`
   */
  function __moveVotingPower(address _from, address _to, uint256 _value) private {
    // if there is no move (`_from == _to`) or there is nothing to move (`_value == 0`)
    if(_from == _to || _value == 0) {
      // return silently with no action
      return;
    }

    // if source address is not zero - decrease its voting power
    if(_from != address(0)) {
      // read current source address voting power
      uint256 _fromVal = getVotingPower(_from);

      // calculate decreased voting power
      // underflow is not possible by design:
      // voting power is limited by token balance which is checked by the callee
      uint256 _toVal = _fromVal - _value;

      // update source voting power from `_fromVal` to `_toVal`
      __updateVotingPower(_from, _fromVal, _toVal);
    }

    // if destination address is not zero - increase its voting power
    if(_to != address(0)) {
      // read current destination address voting power
      uint256 _fromVal = getVotingPower(_to);

      // calculate increased voting power
      // overflow is not possible by design:
      // max token supply limits the cumulative voting power
      uint256 _toVal = _fromVal + _value;

      // update destination voting power from `_fromVal` to `_toVal`
      __updateVotingPower(_to, _fromVal, _toVal);
    }
  }

  /**
   * @dev Auxiliary function to update voting power of the delegate `_of`
   *      from value `_fromVal` to value `_toVal`
   *
   * @param _of delegate to update its voting power
   * @param _fromVal old voting power of the delegate
   * @param _toVal new voting power of the delegate
   */
  function __updateVotingPower(address _of, uint256 _fromVal, uint256 _toVal) private {
    // get a link to an array of voting power history records for an address specified
    VotingPowerRecord[] storage history = votingPowerHistory[_of];

    // if there is an existing voting power value stored for current block
    if(history.length != 0 && history[history.length - 1].blockNumber == block.number) {
      // update voting power which is already stored in the current block
      history[history.length - 1].votingPower = uint192(_toVal);
    }
    // otherwise - if there is no value stored for current block
    else {
      // add new element into array representing the value for current block
      history.push(VotingPowerRecord(uint64(block.number), uint192(_toVal)));
    }

    // emit an event
    emit VotingPowerChanged(_of, _fromVal, _toVal);
  }

  /**
   * @dev Auxiliary function to lookup an element in a sorted (asc) array of elements
   *
   * @dev This function finds the closest element in an array to the value
   *      of interest (not exceeding that value) and returns its index within an array
   *
   * @dev An array to search in is `votingPowerHistory[_to][i].blockNumber`,
   *      it is sorted in ascending order (blockNumber increases)
   *
   * @param _to an address of the delegate to get an array for
   * @param n value of interest to look for
   * @return an index of the closest element in an array to the value
   *      of interest (not exceeding that value)
   */
  function __binaryLookup(address _to, uint256 n) private view returns(uint256) {
    // get a link to an array of voting power history records for an address specified
    VotingPowerRecord[] storage history = votingPowerHistory[_to];

    // left bound of the search interval, originally start of the array
    uint256 i = 0;

    // right bound of the search interval, originally end of the array
    uint256 j = history.length - 1;

    // the iteration process narrows down the bounds by
    // splitting the interval in a half oce per each iteration
    while(j > i) {
      // get an index in the middle of the interval [i, j]
      uint256 k = j - (j - i) / 2;

      // read an element to compare it with the value of interest
      VotingPowerRecord memory cp = history[k];

      // if we've got a strict equal - we're lucky and done
      if(cp.blockNumber == n) {
        // just return the result - index `k`
        return k;
      }
      // if the value of interest is bigger - move left bound to the middle
      else if (cp.blockNumber < n) {
        // move left bound `i` to the middle position `k`
        i = k;
      }
      // otherwise, when the value of interest is smaller - move right bound to the middle
      else {
        // move right bound `j` to the middle position `k - 1`:
        // element at position `k` is bigger and cannot be the result
        j = k - 1;
      }
    }

    // reaching that point means no exact match found
    // since we're interested in the element which is not bigger than the
    // element of interest, we return the lower bound `i`
    return i;
  }
}

// ===== End: DAO Support (Compound-like voting delegation) =====

// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;

/**
 * @title Access Control List
 *
 * @notice Access control smart contract provides an API to check
 *      if specific operation is permitted globally and/or
 *      if particular user has a permission to execute it.
 *
 * @notice It deals with two main entities: features and roles.
 *
 * @notice Features are designed to be used to enable/disable specific
 *      functions (public functions) of the smart contract for everyone.
 * @notice User roles are designed to restrict access to specific
 *      functions (restricted functions) of the smart contract to some users.
 *
 * @notice Terms "role", "permissions" and "set of permissions" have equal meaning
 *      in the documentation text and may be used interchangeably.
 * @notice Terms "permission", "single permission" implies only one permission bit set.
 *
 * @dev This smart contract is designed to be inherited by other
 *      smart contracts which require access control management capabilities.
 *
 * @author Basil Gorin
 */
contract AccessControl {
  /**
   * @notice Access manager is responsible for assigning the roles to users,
   *      enabling/disabling global features of the smart contract
   * @notice Access manager can add, remove and update user roles,
   *      remove and update global features
   *
   * @dev Role ROLE_ACCESS_MANAGER allows modifying user roles and global features
   * @dev Role ROLE_ACCESS_MANAGER has single bit at position 255 enabled
   */
  uint256 public constant ROLE_ACCESS_MANAGER = 0x8000000000000000000000000000000000000000000000000000000000000000;

  /**
   * @dev Bitmask representing all the possible permissions (super admin role)
   * @dev Has all the bits are enabled (2^256 - 1 value)
   */
  uint256 private constant FULL_PRIVILEGES_MASK = type(uint256).max; // before 0.8.0: uint256(-1) overflows to 0xFFFF...

  /**
   * @notice Privileged addresses with defined roles/permissions
   * @notice In the context of ERC20/ERC721 tokens these can be permissions to
   *      allow minting or burning tokens, transferring on behalf and so on
   *
   * @dev Maps user address to the permissions bitmask (role), where each bit
   *      represents a permission
   * @dev Bitmask 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
   *      represents all possible permissions
   * @dev Zero address mapping represents global features of the smart contract
   */
  mapping(address => uint256) public userRoles;

  /**
   * @dev Fired in updateRole() and updateFeatures()
   *
   * @param _by operator which called the function
   * @param _to address which was granted/revoked permissions
   * @param _requested permissions requested
   * @param _actual permissions effectively set
   */
  event RoleUpdated(address indexed _by, address indexed _to, uint256 _requested, uint256 _actual);

  /**
   * @notice Creates an access control instance,
   *      setting contract creator to have full privileges
   */
  constructor() {
    // contract creator has full privileges
    userRoles[msg.sender] = FULL_PRIVILEGES_MASK;
  }

  /**
   * @notice Retrieves globally set of features enabled
   *
   * @dev Auxiliary getter function to maintain compatibility with previous
   *      versions of the Access Control List smart contract, where
   *      features was a separate uint256 public field
   *
   * @return 256-bit bitmask of the features enabled
   */
  function features() public view returns(uint256) {
    // according to new design features are stored in zero address
    // mapping of `userRoles` structure
    return userRoles[address(0)];
  }

  /**
   * @notice Updates set of the globally enabled features (`features`),
   *      taking into account sender's permissions
   *
   * @dev Requires transaction sender to have `ROLE_ACCESS_MANAGER` permission
   * @dev Function is left for backward compatibility with older versions
   *
   * @param _mask bitmask representing a set of features to enable/disable
   */
  function updateFeatures(uint256 _mask) public {
    // delegate call to `updateRole`
    updateRole(address(0), _mask);
  }

  /**
   * @notice Updates set of permissions (role) for a given user,
   *      taking into account sender's permissions.
   *
   * @dev Setting role to zero is equivalent to removing an all permissions
   * @dev Setting role to `FULL_PRIVILEGES_MASK` is equivalent to
   *      copying senders' permissions (role) to the user
   * @dev Requires transaction sender to have `ROLE_ACCESS_MANAGER` permission
   *
   * @param operator address of a user to alter permissions for or zero
   *      to alter global features of the smart contract
   * @param role bitmask representing a set of permissions to
   *      enable/disable for a user specified
   */
  function updateRole(address operator, uint256 role) public {
    // caller must have a permission to update user roles
    require(isSenderInRole(ROLE_ACCESS_MANAGER), "insufficient privileges (ROLE_ACCESS_MANAGER required)");

    // evaluate the role and reassign it
    userRoles[operator] = evaluateBy(msg.sender, userRoles[operator], role);

    // fire an event
    emit RoleUpdated(msg.sender, operator, role, userRoles[operator]);
  }

  /**
   * @notice Determines the permission bitmask an operator can set on the
   *      target permission set
   * @notice Used to calculate the permission bitmask to be set when requested
   *     in `updateRole` and `updateFeatures` functions
   *
   * @dev Calculated based on:
   *      1) operator's own permission set read from userRoles[operator]
   *      2) target permission set - what is already set on the target
   *      3) desired permission set - what do we want set target to
   *
   * @dev Corner cases:
   *      1) Operator is super admin and its permission set is `FULL_PRIVILEGES_MASK`:
   *        `desired` bitset is returned regardless of the `target` permission set value
   *        (what operator sets is what they get)
   *      2) Operator with no permissions (zero bitset):
   *        `target` bitset is returned regardless of the `desired` value
   *        (operator has no authority and cannot modify anything)
   *
   * @dev Example:
   *      Consider an operator with the permissions bitmask     00001111
   *      is about to modify the target permission set          01010101
   *      Operator wants to set that permission set to          00110011
   *      Based on their role, an operator has the permissions
   *      to update only lowest 4 bits on the target, meaning that
   *      high 4 bits of the target set in this example is left
   *      unchanged and low 4 bits get changed as desired:      01010011
   *
   * @param operator address of the contract operator which is about to set the permissions
   * @param target input set of permissions to operator is going to modify
   * @param desired desired set of permissions operator would like to set
   * @return resulting set of permissions given operator will set
   */
  function evaluateBy(address operator, uint256 target, uint256 desired) public view returns(uint256) {
    // read operator's permissions
    uint256 p = userRoles[operator];

    // taking into account operator's permissions,
    // 1) enable the permissions desired on the `target`
    target |= p & desired;
    // 2) disable the permissions desired on the `target`
    target &= FULL_PRIVILEGES_MASK ^ (p & (FULL_PRIVILEGES_MASK ^ desired));

    // return calculated result
    return target;
  }

  /**
   * @notice Checks if requested set of features is enabled globally on the contract
   *
   * @param required set of features to check against
   * @return true if all the features requested are enabled, false otherwise
   */
  function isFeatureEnabled(uint256 required) public view returns(bool) {
    // delegate call to `__hasRole`, passing `features` property
    return __hasRole(features(), required);
  }

  /**
   * @notice Checks if transaction sender `msg.sender` has all the permissions required
   *
   * @param required set of permissions (role) to check against
   * @return true if all the permissions requested are enabled, false otherwise
   */
  function isSenderInRole(uint256 required) public view returns(bool) {
    // delegate call to `isOperatorInRole`, passing transaction sender
    return isOperatorInRole(msg.sender, required);
  }

  /**
   * @notice Checks if operator has all the permissions (role) required
   *
   * @param operator address of the user to check role for
   * @param required set of permissions (role) to check
   * @return true if all the permissions requested are enabled, false otherwise
   */
  function isOperatorInRole(address operator, uint256 required) public view returns(bool) {
    // delegate call to `__hasRole`, passing operator's permissions (role)
    return __hasRole(userRoles[operator], required);
  }

  /**
   * @dev Checks if role `actual` contains all the permissions required `required`
   *
   * @param actual existent role
   * @param required required role
   * @return true if actual has required role (all permissions), false otherwise
   */
  function __hasRole(uint256 actual, uint256 required) internal pure returns(bool) {
    // check the bitmask for the role required and return the result
    return actual & required == required;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;

/**
 * @title Address Utils
 *
 * @dev Utility library of inline functions on addresses
 *
 * @author Basil Gorin
 */
library AddressUtils {

  /**
   * @notice Checks if the target address is a contract
   * @dev This function will return false if invoked during the constructor of a contract,
   *      as the code is not actually created until after the constructor finishes.
   * @param addr address to check
   * @return whether the target address is a contract
   */
  function isContract(address addr) internal view returns (bool) {
    // a variable to load `extcodesize` to
    uint256 size = 0;

    // XXX Currently there is no better way to check if there is a contract in an address
    // than to check the size of the code at that address.
    // See https://ethereum.stackexchange.com/a/14016/36603 for more details about how this works.
    // TODO: Check this again before the Serenity release, because all addresses will be contracts.
    // solium-disable-next-line security/no-inline-assembly
    assembly {
      // retrieve the size of the code at address `addr`
      size := extcodesize(addr)
    }

    // positive size indicates a smart contract address
    return size > 0;
  }

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;

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
abstract contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        address msgSender = msg.sender;
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        require(owner() == msg.sender, "Ownable: caller is not the owner");
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
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

{
  "remappings": [],
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "evmVersion": "istanbul",
  "libraries": {},
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}