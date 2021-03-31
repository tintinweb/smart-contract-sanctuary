/**
 *Submitted for verification at Etherscan.io on 2021-03-31
*/

pragma solidity 0.8.2;


abstract contract IERC20WithCheckpointing {
    function balanceOf(address _owner) public view virtual returns (uint256);

    function balanceOfAt(address _owner, uint256 _blockNumber)
        public
        view
        virtual
        returns (uint256);

    function totalSupply() public view virtual returns (uint256);

    function totalSupplyAt(uint256 _blockNumber) public view virtual returns (uint256);
}

abstract contract IIncentivisedVotingLockup is IERC20WithCheckpointing {
    function getLastUserPoint(address _addr)
        external
        view
        virtual
        returns (
            int128 bias,
            int128 slope,
            uint256 ts
        );

    function createLock(uint256 _value, uint256 _unlockTime) external virtual;

    function withdraw() external virtual;

    function increaseLockAmount(uint256 _value) external virtual;

    function increaseLockLength(uint256 _unlockTime) external virtual;

    function eject(address _user) external virtual;

    function expireContract() external virtual;

    function claimReward() public virtual;

    function earned(address _account) public view virtual returns (uint256);
}

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

interface IBoostedVaultWithLockup {
    /**
     * @dev Stakes a given amount of the StakingToken for the sender
     * @param _amount Units of StakingToken
     */
    function stake(uint256 _amount) external;

    /**
     * @dev Stakes a given amount of the StakingToken for a given beneficiary
     * @param _beneficiary Staked tokens are credited to this address
     * @param _amount      Units of StakingToken
     */
    function stake(address _beneficiary, uint256 _amount) external;

    /**
     * @dev Withdraws stake from pool and claims any unlocked rewards.
     * Note, this function is costly - the args for _claimRewards
     * should be determined off chain and then passed to other fn
     */
    function exit() external;

    /**
     * @dev Withdraws stake from pool and claims any unlocked rewards.
     * @param _first    Index of the first array element to claim
     * @param _last     Index of the last array element to claim
     */
    function exit(uint256 _first, uint256 _last) external;

    /**
     * @dev Withdraws given stake amount from the pool
     * @param _amount Units of the staked token to withdraw
     */
    function withdraw(uint256 _amount) external;

    /**
     * @dev Claims only the tokens that have been immediately unlocked, not including
     * those that are in the lockers.
     */
    function claimReward() external;

    /**
     * @dev Claims all unlocked rewards for sender.
     * Note, this function is costly - the args for _claimRewards
     * should be determined off chain and then passed to other fn
     */
    function claimRewards() external;

    /**
     * @dev Claims all unlocked rewards for sender. Both immediately unlocked
     * rewards and also locked rewards past their time lock.
     * @param _first    Index of the first array element to claim
     * @param _last     Index of the last array element to claim
     */
    function claimRewards(uint256 _first, uint256 _last) external;

    /**
     * @dev Pokes a given account to reset the boost
     */
    function pokeBoost(address _account) external;

    /**
     * @dev Gets the last applicable timestamp for this reward period
     */
    function lastTimeRewardApplicable() external view returns (uint256);

    /**
     * @dev Calculates the amount of unclaimed rewards per token since last update,
     * and sums with stored to give the new cumulative reward per token
     * @return 'Reward' per staked token
     */
    function rewardPerToken() external view returns (uint256);

    /**
     * @dev Returned the units of IMMEDIATELY claimable rewards a user has to receive. Note - this
     * does NOT include the majority of rewards which will be locked up.
     * @param _account User address
     * @return Total reward amount earned
     */
    function earned(address _account) external view returns (uint256);

    /**
     * @dev Calculates all unclaimed reward data, finding both immediately unlocked rewards
     * and those that have passed their time lock.
     * @param _account User address
     * @return amount Total units of unclaimed rewards
     * @return first Index of the first userReward that has unlocked
     * @return last Index of the last userReward that has unlocked
     */
    function unclaimedRewards(address _account)
        external
        view
        returns (
            uint256 amount,
            uint256 first,
            uint256 last
        );
}

interface IBoostDirector {
    function getBalance(address _user) external returns (uint256);

    function setDirection(
        address _old,
        address _new,
        bool _pokeNew
    ) external;

    function whitelistVaults(address[] calldata _vaults) external;
}

contract ModuleKeys {
    // Governance
    // ===========
    // keccak256("Governance");
    bytes32 internal constant KEY_GOVERNANCE =
        0x9409903de1e6fd852dfc61c9dacb48196c48535b60e25abf92acc92dd689078d;
    //keccak256("Staking");
    bytes32 internal constant KEY_STAKING =
        0x1df41cd916959d1163dc8f0671a666ea8a3e434c13e40faef527133b5d167034;
    //keccak256("ProxyAdmin");
    bytes32 internal constant KEY_PROXY_ADMIN =
        0x96ed0203eb7e975a4cbcaa23951943fa35c5d8288117d50c12b3d48b0fab48d1;

    // mStable
    // =======
    // keccak256("OracleHub");
    bytes32 internal constant KEY_ORACLE_HUB =
        0x8ae3a082c61a7379e2280f3356a5131507d9829d222d853bfa7c9fe1200dd040;
    // keccak256("Manager");
    bytes32 internal constant KEY_MANAGER =
        0x6d439300980e333f0256d64be2c9f67e86f4493ce25f82498d6db7f4be3d9e6f;
    //keccak256("Recollateraliser");
    bytes32 internal constant KEY_RECOLLATERALISER =
        0x39e3ed1fc335ce346a8cbe3e64dd525cf22b37f1e2104a755e761c3c1eb4734f;
    //keccak256("MetaToken");
    bytes32 internal constant KEY_META_TOKEN =
        0xea7469b14936af748ee93c53b2fe510b9928edbdccac3963321efca7eb1a57a2;
    // keccak256("SavingsManager");
    bytes32 internal constant KEY_SAVINGS_MANAGER =
        0x12fe936c77a1e196473c4314f3bed8eeac1d757b319abb85bdda70df35511bf1;
    // keccak256("Liquidator");
    bytes32 internal constant KEY_LIQUIDATOR =
        0x1e9cb14d7560734a61fa5ff9273953e971ff3cd9283c03d8346e3264617933d4;
    // keccak256("InterestValidator");
    bytes32 internal constant KEY_INTEREST_VALIDATOR =
        0xc10a28f028c7f7282a03c90608e38a4a646e136e614e4b07d119280c5f7f839f;
}

interface INexus {
    function governor() external view returns (address);

    function getModule(bytes32 key) external view returns (address);

    function proposeModule(bytes32 _key, address _addr) external;

    function cancelProposedModule(bytes32 _key) external;

    function acceptProposedModule(bytes32 _key) external;

    function acceptProposedModules(bytes32[] calldata _keys) external;

    function requestLockModule(bytes32 _key) external;

    function cancelLockModule(bytes32 _key) external;

    function lockModule(bytes32 _key) external;
}

abstract contract ImmutableModule is ModuleKeys {
    INexus public immutable nexus;

    /**
     * @dev Initialization function for upgradable proxy contracts
     * @param _nexus Nexus contract address
     */
    constructor(address _nexus) {
        require(_nexus != address(0), "Nexus address is zero");
        nexus = INexus(_nexus);
    }

    /**
     * @dev Modifier to allow function calls only from the Governor.
     */
    modifier onlyGovernor() {
        _onlyGovernor();
        _;
    }

    function _onlyGovernor() internal view {
        require(msg.sender == _governor(), "Only governor can execute");
    }

    /**
     * @dev Modifier to allow function calls only from the Governance.
     *      Governance is either Governor address or Governance address.
     */
    modifier onlyGovernance() {
        require(
            msg.sender == _governor() || msg.sender == _governance(),
            "Only governance can execute"
        );
        _;
    }

    /**
     * @dev Modifier to allow function calls only from the ProxyAdmin.
     */
    modifier onlyProxyAdmin() {
        require(msg.sender == _proxyAdmin(), "Only ProxyAdmin can execute");
        _;
    }

    /**
     * @dev Modifier to allow function calls only from the Manager.
     */
    modifier onlyManager() {
        require(msg.sender == _manager(), "Only manager can execute");
        _;
    }

    /**
     * @dev Returns Governor address from the Nexus
     * @return Address of Governor Contract
     */
    function _governor() internal view returns (address) {
        return nexus.governor();
    }

    /**
     * @dev Returns Governance Module address from the Nexus
     * @return Address of the Governance (Phase 2)
     */
    function _governance() internal view returns (address) {
        return nexus.getModule(KEY_GOVERNANCE);
    }

    /**
     * @dev Return Staking Module address from the Nexus
     * @return Address of the Staking Module contract
     */
    function _staking() internal view returns (address) {
        return nexus.getModule(KEY_STAKING);
    }

    /**
     * @dev Return ProxyAdmin Module address from the Nexus
     * @return Address of the ProxyAdmin Module contract
     */
    function _proxyAdmin() internal view returns (address) {
        return nexus.getModule(KEY_PROXY_ADMIN);
    }

    /**
     * @dev Return MetaToken Module address from the Nexus
     * @return Address of the MetaToken Module contract
     */
    function _metaToken() internal view returns (address) {
        return nexus.getModule(KEY_META_TOKEN);
    }

    /**
     * @dev Return OracleHub Module address from the Nexus
     * @return Address of the OracleHub Module contract
     */
    function _oracleHub() internal view returns (address) {
        return nexus.getModule(KEY_ORACLE_HUB);
    }

    /**
     * @dev Return Manager Module address from the Nexus
     * @return Address of the Manager Module contract
     */
    function _manager() internal view returns (address) {
        return nexus.getModule(KEY_MANAGER);
    }

    /**
     * @dev Return SavingsManager Module address from the Nexus
     * @return Address of the SavingsManager Module contract
     */
    function _savingsManager() internal view returns (address) {
        return nexus.getModule(KEY_SAVINGS_MANAGER);
    }

    /**
     * @dev Return Recollateraliser Module address from the Nexus
     * @return  Address of the Recollateraliser Module contract (Phase 2)
     */
    function _recollateraliser() internal view returns (address) {
        return nexus.getModule(KEY_RECOLLATERALISER);
    }
}


// Internal
/**
 * @title  BoostDirector
 * @author mStable
 * @notice Supports the directing of vMTA balance from Staking up to X accounts
 * @dev    Uses a bitmap to store the id's of a given users chosen vaults in a gas efficient manner.
 */
contract BoostDirector is IBoostDirector, ImmutableModule {

    event Directed(address user, address boosted);
    event RedirectedBoost(address user, address boosted, address replaced);
    event Whitelisted(address vaultAddress, uint8 vaultId);

    // Read the vMTA balance from here
    IIncentivisedVotingLockup public immutable stakingContract;

    // Whitelisted vaults set by governance (only these vaults can read balances)
    uint8 private vaultCount;
    // Vault address -> internal id for tracking
    mapping(address => uint8) public _vaults;
    // uint128 packed with up to 16 uint8's. Each uint is a vault ID
    mapping(address => uint128) public _directedBitmap;


    /***************************************
                      ADMIN
    ****************************************/

    // Simple constructor
    constructor(address _nexus, address _stakingContract) ImmutableModule(_nexus) {
        stakingContract = IIncentivisedVotingLockup(_stakingContract);
    }

    /**
     * @dev Initialize function - simply sets the initial array of whitelisted vaults
     */
    function initialize(address[] calldata _newVaults) external {
        require(vaultCount == 0, "Already initialized");
        _whitelistVaults(_newVaults);
    }

    /**
     * @dev Whitelist vaults - only callable by governance. Whitelists vaults, unless they
     * have already been whitelisted
     */
    function whitelistVaults(address[] calldata _newVaults) external override onlyGovernor {
        _whitelistVaults(_newVaults);
    }

    /**
     * @dev Takes an array of newVaults. For each, determines if it is already whitelisted.
     * If not, then increment vaultCount and same the vault with new ID
     */
    function _whitelistVaults(address[] calldata _newVaults) internal {
        uint256 len = _newVaults.length;
        require(len > 0, "Must be at least one vault");
        for (uint256 i = 0; i < len; i++) {
            uint8 id = _vaults[_newVaults[i]];
            require(id == 0, "Vault already whitelisted");

            vaultCount += 1;
            _vaults[_newVaults[i]] = vaultCount;

            emit Whitelisted(_newVaults[i], vaultCount);
        }
    }


    /***************************************
                      Vault
    ****************************************/

    /**
     * @dev Gets the balance of a user that has been directed to the caller (a vault).
     * If the user has not directed to this vault, or there are less than 3 directed,
     * then add this to the list
     * @param _user     Address of the user for which to get balance
     * @return Directed balance
     */
    function getBalance(address _user) external override returns (uint256) {
        // Get vault details
        uint8 id = _vaults[msg.sender];
        // If vault has not been whitelisted, just return zero
        if(id == 0) return 0;

        // Get existing bitmap and balance
        uint128 bitmap = _directedBitmap[_user];
        uint256 bal = stakingContract.balanceOf(_user);

        (bool isWhitelisted, uint8 count, ) = _indexExists(bitmap, id);

        if (isWhitelisted) return bal;

        if (count < 3) {
            _directedBitmap[_user] = _direct(bitmap, count, id);
            emit Directed(_user, msg.sender);
            return bal;
        }

        if (count >= 3) return 0;
    }

    /**
     * @dev Directs rewards to a vault, and removes them from the old vault. Provided
     * that old is active and the new vault is whitelisted.
     * @param _old     Address of the old vault that will no longer get boosted
     * @param _new     Address of the new vault that will get boosted
     * @param _pokeNew Bool to say if we should poke the boost on the new vault
     */
    function setDirection(
        address _old,
        address _new,
        bool _pokeNew
    ) external override {
        uint8 idOld = _vaults[_old];
        uint8 idNew = _vaults[_new];

        require(idOld > 0 && idNew > 0, "Vaults not whitelisted");

        uint128 bitmap = _directedBitmap[msg.sender];
        (bool isWhitelisted, uint8 count, uint8 pos) = _indexExists(bitmap, idOld);
        require(isWhitelisted && count >= 3, "No need to replace old");

        _directedBitmap[msg.sender] = _direct(bitmap, pos, idNew);

        IBoostedVaultWithLockup(_old).pokeBoost(msg.sender);

        if (_pokeNew) {
            IBoostedVaultWithLockup(_new).pokeBoost(msg.sender);
        }

        emit RedirectedBoost(msg.sender, _new, _old);
    }

    /**
     * @dev Resets the bitmap given the new _id for _pos. Takes each uint8 in seperate and re-compiles
     */
    function _direct(
        uint128 _bitmap,
        uint8 _pos,
        uint8 _id
    ) internal returns (uint128 newMap) {
        // bitmap          = ... 00000000 00000000 00000011 00001010
        // pos = 1, id = 1 = 00000001
        // step            = ... 00000000 00000000 00000001 00000000
        uint8 id;
        uint128 step;
        for (uint8 i = 0; i < 3; i++) {
            unchecked {
                // id is either the one that is passed, or existing
                id = _pos == i ? _id : uint8(_bitmap >> (i * 8));
                step = uint128(uint128(id) << (i * 8));
            }
            newMap |= step;
        }
    }

    /**
     * @dev Given a 128 bit bitmap packed with 8 bit ids, should be able to filter for specific ids by moving
     * the bitmap gradually to the right and reading each 8 bit section as a uint8.
     */
    function _indexExists(uint128 _bitmap, uint8 _target)
        internal
        view
        returns (
            bool isWhitelisted,
            uint8 count,
            uint8 pos
        )
    {
        // bitmap   = ... 00000000 00000000 00000011 00001010 // positions 1 and 2 have ids 10 and 3 respectively
        // e.g.
        // i = 1: bitmap moves 8 bits to the right
        // bitmap   = ... 00000000 00000000 00000000 00000011 // reading uint8 should return 3
        uint8 id;
        for (uint8 i = 0; i < 3; i++) {
            unchecked {
                id = uint8(_bitmap >> (i * 8));
            }
            if (id > 0) count += 1;
            if (id == _target) {
                isWhitelisted = true;
                pos = i;
            }
        }
    }
}