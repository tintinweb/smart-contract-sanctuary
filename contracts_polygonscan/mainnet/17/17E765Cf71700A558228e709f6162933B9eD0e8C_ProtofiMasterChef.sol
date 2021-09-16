// SPDX-License-Identifier: MIT
pragma solidity >= 0.6.12;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "./libs/ProtofiERC20.sol";
import "./interfaces/IMoneyPot.sol";

/**
This is the contract of the secondary token.

Features:
- Ownable
- Keeps track of every holder
- Can be swapped for the primary tokens
- Keeps track of the penalty over time to swap this token for the primary token

Owner --> Masterchef for farming features
 */
contract ElectronToken is ProtofiERC20("Electron Token", "ELCT") {
    using SafeMath for uint256;

    struct HolderInfo {
        uint256 avgTransactionBlock;
    }

    ProtofiERC20 public proton;
    bool private _isProtonSetup = false;

    IMoneyPot public moneyPot;
    bool private _isMoneyPotSetup = false;

    /// Penalty period expressed in blocks.
    uint256 public immutable SWAP_PENALTY_MAX_PERIOD; // default 129600 blocks (3d*24h*60m*60sec/2sec): after 72h penalty of holding electron, swap penalty is at the minimum (zero penalty)
    /// Penalty expressed in percentage points --> e.g. 30 means 30% of penalty
    uint256 public immutable SWAP_PENALTY_MAX_PER_ELCT; // default: 30, 30% => 1 electron = 0.7 proton

    // Keeps track of all the historical holders of Electron
    address[] private holdersAddresses;
    // Keeps track of all the addresses added to holdersAddresses
    mapping (address => bool) public wallets;
    // Keeps track of useful infos for each holder
    mapping(address => HolderInfo) public holdersInfo;

    constructor (uint256 swapPenaltyMaxPeriod, uint256 swapPenaltyMaxPerElectron) public{
        SWAP_PENALTY_MAX_PERIOD = swapPenaltyMaxPeriod;
        SWAP_PENALTY_MAX_PER_ELCT = swapPenaltyMaxPerElectron.mul(1e10);
    }

    /// Sets the reference to the primary token, can be done only once, be careful!
    function setupProton(ProtofiERC20 _proton) external onlyOwner {
        require(!_isProtonSetup, "The Proton token has already been set up. No one can change it anymore.");
        proton = _proton;
        _isProtonSetup = true;
    }

    /// Sets the reference to the MoneyPot, can be done only once, be careful!
    function setupMoneyPot(IMoneyPot _moneyPot) external onlyOwner {
        require(!_isMoneyPotSetup, "The Moneypot has already been set up. No one can change it anymore.");
        moneyPot = _moneyPot;
        _isMoneyPotSetup = true;
    }

    /**
    Calculate the penality for swapping ELCT to PROTO for a user.
    The penality decrease over time (by holding duration).
    From SWAP_PENALTY_MAX_PER_ELCT % to 0% on SWAP_PENALTY_MAX_PERIOD
    */
    function getPenaltyPercent(address _holderAddress) public view returns (uint256){
        HolderInfo storage holderInfo = holdersInfo[_holderAddress];
        if(block.number >= holderInfo.avgTransactionBlock.add(SWAP_PENALTY_MAX_PERIOD)){
            return 0;
        }
        if(block.number == holderInfo.avgTransactionBlock){
            return SWAP_PENALTY_MAX_PER_ELCT;
        }
        uint256 avgHoldingDuration = block.number.sub(holderInfo.avgTransactionBlock);
        return SWAP_PENALTY_MAX_PER_ELCT.sub(
            SWAP_PENALTY_MAX_PER_ELCT.mul(avgHoldingDuration).div(SWAP_PENALTY_MAX_PERIOD)
        );
    }

    /// Allow use to exchange (swap) their electron to proton
    function swapToProton(uint256 _amount) external {
        require(_amount > 0, "amount 0");
        address _from = msg.sender;
        // Get the amount of the primary token to be received
        uint256 protonAmount = _swapProtonAmount( _from, _amount);
        holdersInfo[_from].avgTransactionBlock = _getAvgTransactionBlock(_from, holdersInfo[_from], _amount, true);
        
        // Burn ELCT and mint PROTO
        super._burn(_from, _amount);

        // Moving delegates with the call to _burn
        emit DelegateChanged(_from, _delegates[_from], _delegates[BURN_ADDRESS]);
        _moveDelegates(_delegates[_from], _delegates[BURN_ADDRESS], _amount);

        proton.mint(_from, protonAmount);

        if (address(moneyPot) != address(0)) {
            moneyPot.updateElectronHolder(_from);
        }
    }

    /**
    @notice Preview swap return in proton with _electronAmount by _holderAddress
    this function is used by front-end to show how much PROTO will be retrieved if _holderAddress swap _electronAmount
    */
    function previewSwapProtonExpectedAmount(address _holderAddress, uint256 _electronAmount) external view returns (uint256 expectedProton){
        return _swapProtonAmount( _holderAddress, _electronAmount);
    }

    /**
    @notice Preview swap return in proton from all the addresses holding ELCT
    This function is used by front-end to show how much PROTO will be generated if all the holders of ELCT swap all ELCTS for PROTOS
    */
    function previewTotalSwapElectronToProton() external view returns (uint256 expectedProton){

        uint256 totalProton = 0;
        // For each holder, update the total PROTOs that can be generated
        for(uint index = 0; index < holdersAddresses.length; index++){
            address tmpaddress = holdersAddresses[index];
            uint256 tmpbalance = balanceOf(tmpaddress);
            totalProton = totalProton.add(_swapProtonAmount(tmpaddress, tmpbalance));
        }
        return totalProton;
    }

    /// @notice Calculate the adjustment for a user if he want to swap _electronAmount to proton
    function _swapProtonAmount(address _holderAddress, uint256 _electronAmount) internal view returns (uint256 expectedProton){
        require(balanceOf(_holderAddress) >= _electronAmount, "Not enough electron");
        uint256 penalty = getPenaltyPercent(_holderAddress);
        if(penalty == 0){
            return _electronAmount;
        }

        return _electronAmount.sub(_electronAmount.mul(penalty).div(1e12));
    }

    /**
    @notice Calculate average deposit/withdraw block for _holderAddress

    @dev The average transaction block is:
    - set to 0 if the user swaps all his electron to proton
    - set to the previous avgTransactionBlock if the user does not swap all his electron
    - is updated if the holder gets new electron
    Basically, avgTransactionBlock is updated to a higher value only if _holderAddress receives new electron,
    otherwise avgTransactionBlock stays the same or go to 0 if everything is swapped or sent.
     */
    function _getAvgTransactionBlock(address _holderAddress, HolderInfo storage holderInfo, uint256 _electronAmount, bool _onWithdraw) internal view returns (uint256){
        if (balanceOf(_holderAddress) == 0) {
            return block.number;
        }
        uint256 minAvgTransactionBlockPossible = block.number.sub(SWAP_PENALTY_MAX_PERIOD);
        uint256 holderAvgTransactionBlock = holderInfo.avgTransactionBlock > minAvgTransactionBlockPossible ? holderInfo.avgTransactionBlock : minAvgTransactionBlockPossible;

        uint256 transactionBlockWeight;
        if (_onWithdraw) {
            if (balanceOf(_holderAddress) == _electronAmount) {
                return 0; // Average transaction block is the lowest possible block
            }
            else {
                return holderAvgTransactionBlock;
            }
        }
        else {
            transactionBlockWeight = (balanceOf(_holderAddress).mul(holderAvgTransactionBlock).add(block.number.mul(_electronAmount)));
        }

        uint256 avgTransactionBlock = transactionBlockWeight.div(balanceOf(_holderAddress).add(_electronAmount));
        return avgTransactionBlock > minAvgTransactionBlockPossible ? avgTransactionBlock : minAvgTransactionBlockPossible;
    }


    /// @notice Creates `_amount` token to `_to`.
    function mint(address _to, uint256 _amount) external virtual override onlyOwner {
        HolderInfo storage holder = holdersInfo[_to];
        // avgTransactionBlock is updated accordingly to the amount minted
        holder.avgTransactionBlock = _getAvgTransactionBlock(_to, holder, _amount, false);

        if(wallets[_to] == false){
            // Add holder to historical holders
            holdersAddresses.push(_to);
            wallets[_to] = true;
        }

        _mint(_to, _amount);
        _moveDelegates(address(0), _delegates[_to], _amount);

        if (address(moneyPot) != address(0)) {
            moneyPot.updateElectronHolder(_to);
        }
    }

    /// @dev overrides transfer function to meet tokenomics of ELCT
    function _transfer(address _sender, address _recipient, uint256 _amount) internal virtual override {
        holdersInfo[_sender].avgTransactionBlock = _getAvgTransactionBlock(_sender, holdersInfo[_sender], _amount, true);
        if (_recipient == BURN_ADDRESS) {
            super._burn(_sender, _amount);
            if (address(moneyPot) != address(0)) {
                moneyPot.updateElectronHolder(_sender);
            }
        } else {
            holdersInfo[_recipient].avgTransactionBlock = _getAvgTransactionBlock(_recipient, holdersInfo[_recipient], _amount, false);
            super._transfer(_sender, _recipient, _amount);

            if (address(moneyPot) != address(0)) {
                moneyPot.updateElectronHolder(_sender);
                if (_sender != _recipient){
                    moneyPot.updateElectronHolder(_recipient);
                }
            }
        }
        if(wallets[_recipient] == false){
            // Add holder to historical holders
            holdersAddresses.push(_recipient);
            wallets[_recipient] = true;
        }

        // Moving delegates while transferring tokens - Valid also for the _burn call
        emit DelegateChanged(_sender, _delegates[msg.sender], _delegates[_recipient]);
        _moveDelegates(_delegates[msg.sender], _delegates[_recipient], _amount);
    }

    // Copied and modified from YAM code:
    // https://github.com/yam-finance/yam-protocol/blob/master/contracts/token/YAMGovernanceStorage.sol
    // https://github.com/yam-finance/yam-protocol/blob/master/contracts/token/YAMGovernance.sol
    // Which is copied and modified from COMPOUND:
    // https://github.com/compound-finance/compound-protocol/blob/master/contracts/Governance/Comp.sol

    /// @dev A record of each accounts delegate
    mapping(address => address) internal _delegates;

    /// @notice A checkpoint for marking number of votes from a given block
    struct Checkpoint {
        uint32 fromBlock;
        uint256 votes;
    }

    /// @notice A record of votes checkpoints for each account, by index
    mapping(address => mapping(uint32 => Checkpoint)) public checkpoints;

    /// @notice The number of checkpoints for each account
    mapping(address => uint32) public numCheckpoints;

    /// @notice The EIP-712 typehash for the contract's domain
    bytes32 public constant DOMAIN_TYPEHASH =
    keccak256("EIP712Domain(string name,uint256 chainId,address verifyingContract)");

    /// @notice The EIP-712 typehash for the delegation struct used by the contract
    bytes32 public constant DELEGATION_TYPEHASH =
    keccak256("Delegation(address delegatee,uint256 nonce,uint256 expiry)");

    /// @notice A record of states for signing / validating signatures
    mapping(address => uint) public nonces;

    /// @notice An event thats emitted when an account changes its delegate
    event DelegateChanged(address indexed delegator, address indexed fromDelegate, address indexed toDelegate);

    /// @notice An event thats emitted when a delegate account's vote balance changes
    event DelegateVotesChanged(address indexed delegate, uint previousBalance, uint newBalance);

    /**
     * @notice Delegate votes from `msg.sender` to `delegatee`
     * @param delegator The address to get delegatee for
     */
    function delegates(address delegator)
    external
    view
    returns (address)
    {
        return _delegates[delegator];
    }

    /**
     * @notice Delegate votes from `msg.sender` to `delegatee`
     * @param delegatee The address to delegate votes to
     */
    function delegate(address delegatee) external {
        return _delegate(msg.sender, delegatee);
    }

    /**
     * @notice Delegates votes from signatory to `delegatee`
     * @param delegatee The address to delegate votes to
     * @param nonce The contract state required to match the signature
     * @param expiry The time at which to expire the signature
     * @param v The recovery byte of the signature
     * @param r Half of the ECDSA signature pair
     * @param s Half of the ECDSA signature pair
     */
    function delegateBySig(
        address delegatee,
        uint nonce,
        uint expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    )
    external
    {
        bytes32 domainSeparator = keccak256(
            abi.encode(
                DOMAIN_TYPEHASH,
                keccak256(bytes(name())),
                getChainId(),
                address(this)
            )
        );

        bytes32 structHash = keccak256(
            abi.encode(
                DELEGATION_TYPEHASH,
                delegatee,
                nonce,
                expiry
            )
        );

        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                domainSeparator,
                structHash
            )
        );

        address signatory = ecrecover(digest, v, r, s);
        require(signatory != address(0), "PROTO::delegateBySig: invalid signature");
        require(nonce == nonces[signatory]++, "PROTO::delegateBySig: invalid nonce");
        require(now <= expiry, "PROTO::delegateBySig: signature expired");
        return _delegate(signatory, delegatee);
    }

    /**
     * @notice Gets the current votes balance for `account`
     * @param account The address to get votes balance
     * @return The number of current votes for `account`
     */
    function getCurrentVotes(address account)
    external
    view
    returns (uint256)
    {
        uint32 nCheckpoints = numCheckpoints[account];
        return nCheckpoints > 0 ? checkpoints[account][nCheckpoints - 1].votes : 0;
    }

    /**
     * @notice Determine the prior number of votes for an account as of a block number
     * @dev Block number must be a finalized block or else this function will revert to prevent misinformation.
     * @param account The address of the account to check
     * @param blockNumber The block number to get the vote balance at
     * @return The number of votes the account had as of the given block
     */
    function getPriorVotes(address account, uint blockNumber)
    external
    view
    returns (uint256)
    {
        require(blockNumber < block.number, "PROTO::getPriorVotes: not yet determined");

        uint32 nCheckpoints = numCheckpoints[account];
        if (nCheckpoints == 0) {
            return 0;
        }

        // First check most recent balance
        if (checkpoints[account][nCheckpoints - 1].fromBlock <= blockNumber) {
            return checkpoints[account][nCheckpoints - 1].votes;
        }

        // Next check implicit zero balance
        if (checkpoints[account][0].fromBlock > blockNumber) {
            return 0;
        }

        uint32 lower = 0;
        uint32 upper = nCheckpoints - 1;
        while (upper > lower) {
            uint32 center = upper - (upper - lower) / 2;
            // ceil, avoiding overflow
            Checkpoint memory cp = checkpoints[account][center];
            if (cp.fromBlock == blockNumber) {
                return cp.votes;
            } else if (cp.fromBlock < blockNumber) {
                lower = center;
            } else {
                upper = center - 1;
            }
        }
        return checkpoints[account][lower].votes;
    }

    function _delegate(address delegator, address delegatee)
    internal
    {
        address currentDelegate = _delegates[delegator];
        uint256 delegatorBalance = balanceOf(delegator);
        // balance of underlying PROTOs (not scaled);
        _delegates[delegator] = delegatee;

        emit DelegateChanged(delegator, currentDelegate, delegatee);

        _moveDelegates(currentDelegate, delegatee, delegatorBalance);
    }

    function _moveDelegates(address srcRep, address dstRep, uint256 amount) internal {
        if (srcRep != dstRep && amount > 0) {
            if (srcRep != address(0)) {
                // decrease old representative
                uint32 srcRepNum = numCheckpoints[srcRep];
                uint256 srcRepOld = srcRepNum > 0 ? checkpoints[srcRep][srcRepNum - 1].votes : 0;
                uint256 srcRepNew = srcRepOld.sub(amount);
                _writeCheckpoint(srcRep, srcRepNum, srcRepOld, srcRepNew);
            }

            if (dstRep != address(0)) {
                // increase new representative
                uint32 dstRepNum = numCheckpoints[dstRep];
                uint256 dstRepOld = dstRepNum > 0 ? checkpoints[dstRep][dstRepNum - 1].votes : 0;
                uint256 dstRepNew = dstRepOld.add(amount);
                _writeCheckpoint(dstRep, dstRepNum, dstRepOld, dstRepNew);
            }
        }
    }

    function _writeCheckpoint(
        address delegatee,
        uint32 nCheckpoints,
        uint256 oldVotes,
        uint256 newVotes
    )
    internal
    {
        uint32 blockNumber = safe32(block.number, "PROTO::_writeCheckpoint: block number exceeds 32 bits");

        if (nCheckpoints > 0 && checkpoints[delegatee][nCheckpoints - 1].fromBlock == blockNumber) {
            checkpoints[delegatee][nCheckpoints - 1].votes = newVotes;
        } else {
            checkpoints[delegatee][nCheckpoints] = Checkpoint(blockNumber, newVotes);
            numCheckpoints[delegatee] = nCheckpoints + 1;
        }

        emit DelegateVotesChanged(delegatee, oldVotes, newVotes);
    }

    function safe32(uint n, string memory errorMessage) internal pure returns (uint32) {
        require(n < 2 ** 32, errorMessage);
        return uint32(n);
    }

    function getChainId() internal pure returns (uint) {
        uint256 chainId;
        assembly {chainId := chainid()}
        return chainId;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >= 0.6.12;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

import "./ProtonToken.sol";
import "./ElectronToken.sol";

/**
This is the masterchef of ProtoFi.

It has several features:

- Ownable
- ReentrancyGuard
- Farms with:
--- Lockup period (customizable)
--- Deposit fee (customizable)
--- Primary or secondary tokens as reward

Owner --> Timelock

Base is the Masterchef from Pancake, with several added features and ReentrancyGuard for security reasons
*/
contract ProtofiMasterChef is Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using SafeERC20 for ProtofiERC20;

    // Info of each user.
    struct UserInfo {
        uint256 amount;           // How many LP tokens the user has provided.
        uint256 rewardDebt;       // Reward debt. See explanation below.
        uint256 rewardLockedUp;   // Reward locked up.
        uint256 nextHarvestUntil; // When can the user harvest again.
        //
        // We do some fancy math here. Basically, any point in time, the amount of PROTOs
        // entitled to a user but is pending to be distributed is:
        //
        //   pending reward = (user.amount * pool.accProtonPerShare) - user.rewardDebt
        //
        // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
        //   1. The pool's `accProtonPerShare` (and `lastRewardBlock`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.
    }

    // Info of each pool.
    struct PoolInfo {
        IERC20 lpToken;           // Address of LP token contract.
        uint256 lpSupply;         // Supply of the lp token related to the pool.
        uint256 allocPoint;       // How many allocation points assigned to this pool. PROTOs to distribute per block.
        uint256 lastRewardBlock;  // Last block number that PROTOs distribution occurs.
        uint256 accProtonPerShare; // Accumulated PROTOs per share, times 1e12. See below.
        uint16 depositFeeBP;      // Deposit fee in basis points.
        uint256 harvestInterval;  // Harvest interval in seconds.
        bool isElectronRewards;     // Establishes which token is given as reward for each pool.
    }

    // The PROTO token - Primary token for ProtoFi tokenomics
    ProtonToken public proton;
    // The ELCT token - Secondary (shares) token for ProtoFi tokenomics
    ElectronToken public electron;
    // Dev address.
    address public devAddress;
    // Deposit Fee address
    address public feeAddress;
    // PROTO tokens created per block, number including decimals.
    uint256 public protonPerBlock;
    // Bonus muliplier
    uint256 public constant BONUS_MULTIPLIER = 1;
    // Max harvest interval: 14 days.
    uint256 public constant MAXIMUM_HARVEST_INTERVAL = 14 days; // Cannot be changed, ever!
    // Max deposit fee is at 6% - Gives us a bit of flexibility, in general it will be <= 4.5%
    uint256 public constant MAXIMUM_DEPOSIT_FEES = 600; // Cannot be changed, ever!

    address public constant BURN_ADDRESS = 0x000000000000000000000000000000000000dEaD;

    // Info of each pool.
    PoolInfo[] public poolInfo;
    // Info of each user that stakes LP tokens.
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;
    // Total allocation points. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint = 0;
    // The block number when PROTO mining starts.
    uint256 public startBlock;
    // Total locked up rewards
    uint256 public totalLockedUpRewards;

    // Events, always useful to keep trak
    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event UpdateEmissionRate(address indexed user, uint256 indexed protonPerBlock);
    event RewardLockedUp(address indexed user, uint256 indexed pid, uint256 amountLockedUp);

    event UpdatedDevAddress(address indexed previousDevAddress, address indexed newDevAddress);
    event UpdatedFeeAddress(address indexed previousFeeAddress, address indexed newFeeAddress);

    constructor(
        ProtonToken _proton,
        ElectronToken _electron,
        uint256 _startBlock,
        uint256 _protonPerBlock,
        address _devaddr,
        address _feeAddress
    ) public {
        proton = _proton;
        electron = _electron;
        startBlock = _startBlock;
        protonPerBlock = _protonPerBlock;

        devAddress = _devaddr;
        feeAddress = _feeAddress;

        // No pools are added by default!
    }

    // Checks that poolInfo array has length at least >= _pid
    modifier validatePool(uint256 _pid) {
        require(_pid < poolInfo.length, "validatePool: pool exists?");
        _;
    }

    // Returns the number of pools
    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    // Add a new lp to the pool. Can only be called by the owner.
    function add(uint256 _allocPoint, IERC20 _lpToken,
                uint16 _depositFeeBP, uint256 _harvestInterval,
                bool _isElectronRewards) public onlyOwner {

        // First deposit fee and harvest interval must not be higher than predefined values
        require(_depositFeeBP <= MAXIMUM_DEPOSIT_FEES, "add: invalid deposit fee basis points");
        require(_harvestInterval <= MAXIMUM_HARVEST_INTERVAL, "add: invalid harvest interval");

        // Always update pools
        massUpdatePools();

        uint256 lastRewardBlock = block.number > startBlock ? block.number : startBlock;
        // Update the totalAllocPoint for the whole masterchef!
        totalAllocPoint = totalAllocPoint.add(_allocPoint);

        poolInfo.push(PoolInfo({
            lpToken: _lpToken,
            lpSupply: 0,
            allocPoint: _allocPoint,
            lastRewardBlock: lastRewardBlock,
            accProtonPerShare: 0,
            depositFeeBP: _depositFeeBP,
            harvestInterval: _harvestInterval,
            isElectronRewards: _isElectronRewards
        }));
    }

    // Update the given pool's PROTO allocation point and deposit fee. Can only be called by the owner.
    function set(uint256 _pid, uint256 _allocPoint,
                 uint16 _depositFeeBP, uint256 _harvestInterval,
                 bool _isElectronRewards) public onlyOwner {
        // First deposit fee and harvest interval must not be higher than predefined values
        require(_depositFeeBP <= MAXIMUM_DEPOSIT_FEES, "set: invalid deposit fee basis points");
        require(_harvestInterval <= MAXIMUM_HARVEST_INTERVAL, "set: invalid harvest interval");

        // Always update pools
        massUpdatePools();

        poolInfo[_pid].allocPoint = _allocPoint;
        poolInfo[_pid].depositFeeBP = _depositFeeBP;
        poolInfo[_pid].harvestInterval = _harvestInterval;
        poolInfo[_pid].isElectronRewards = _isElectronRewards;
        uint256 prevAllocPoint = poolInfo[_pid].allocPoint;
        if (prevAllocPoint != _allocPoint) {
            // Update the totalAllocPoint for the whole masterchef!
            totalAllocPoint = totalAllocPoint.sub(prevAllocPoint).add(_allocPoint);
        }
    }

    // Return reward multiplier over the given _from to _to block.
    function getMultiplier(uint256 _from, uint256 _to) public pure returns (uint256) {
        return _to.sub(_from).mul(BONUS_MULTIPLIER);
    }

    // View function to see pending PROTOs on frontend.
    function pendingProton(uint256 _pid, address _user) external view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accProtonPerShare = pool.accProtonPerShare;
        uint256 lpSupply = pool.lpSupply; // Taken from the pool!
        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
            uint256 protonReward = multiplier.mul(protonPerBlock).mul(pool.allocPoint).div(totalAllocPoint);
            accProtonPerShare = accProtonPerShare.add(protonReward.mul(1e12).div(lpSupply));
        }
        uint256 pending = user.amount.mul(accProtonPerShare).div(1e12).sub(user.rewardDebt);
        if(!pool.isElectronRewards){
            // Primary token has a 1.8% burning mechanism on the transfer function, hence
            // we take into account the 1.8% auto-burn
            pending = pending.mul(982).div(1000);
        }
        return pending.add(user.rewardLockedUp);
    }

    // View function to see if user can harvest PROTOs.
    function canHarvest(uint256 _pid, address _user) public view returns (bool) {
        UserInfo storage user = userInfo[_pid][_user];
        return block.timestamp >= user.nextHarvestUntil;
    }

    // Update reward variables for all pools. Be careful of gas spending!
    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }

    // Update reward variables of the given pool to be up-to-date.
    function updatePool(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        if (block.number <= pool.lastRewardBlock) {
            return;
        }
        uint256 lpSupply = pool.lpSupply;
        if (lpSupply == 0 || pool.allocPoint == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }
        uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
        uint256 protonReward = multiplier.mul(protonPerBlock).mul(pool.allocPoint).div(totalAllocPoint);

        // 5% fees to the dev address for salaries + Marketing + Moneypot
        proton.mint(devAddress, protonReward.div(20));

        // 5% To the burning address
        proton.mint(address(this), protonReward.div(20));
        safeProtonTransfer(BURN_ADDRESS, protonReward.div(20));

        if (pool.isElectronRewards){
            electron.mint(address(this), protonReward);
        }
        else{
            proton.mint(address(this), protonReward);
        }
        pool.accProtonPerShare = pool.accProtonPerShare.add(protonReward.mul(1e12).div(lpSupply));
        pool.lastRewardBlock = block.number;
    }

    /**
    Deposit LP tokens to ProtofiMasterChef for PROTO allocation.
    At the same time, updates the Pool and harvests if the user
    is allowed to harvest from this pool
    */
    function deposit(uint256 _pid, uint256 _amount) public nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        updatePool(_pid);
        payOrLockupPendingProton(_pid);
        if (_amount > 0) {
            uint256 balanceBefore = pool.lpToken.balanceOf(address(this));
            pool.lpToken.safeTransferFrom(address(msg.sender), address(this), _amount);
            _amount = pool.lpToken.balanceOf(address(this)).sub(balanceBefore);
            if (pool.depositFeeBP > 0) {
                // Stake paying deposit fees.
                uint256 depositFee = _amount.mul(pool.depositFeeBP).div(10000);
                pool.lpToken.safeTransfer(feeAddress, depositFee);
                user.amount = user.amount.add(_amount).sub(depositFee);
                pool.lpSupply = pool.lpSupply.add(_amount).sub(depositFee);
            } else {
                user.amount = user.amount.add(_amount);
                pool.lpSupply = pool.lpSupply.add(_amount);
            }
        }
        user.rewardDebt = user.amount.mul(pool.accProtonPerShare).div(1e12);
        emit Deposit(msg.sender, _pid, _amount);
    }

    /**
    Withdraw LP tokens from ProtofiMasterChef.
    At the same time, updates the Pool and harvests if the user
    is allowed to harvest from this pool
    */
    function withdraw(uint256 _pid, uint256 _amount) public nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount >= _amount, "withdraw: user amount staked is lower than the requested amount");

        updatePool(_pid);
        payOrLockupPendingProton(_pid);
        if (_amount > 0) {
            user.amount = user.amount.sub(_amount);
            pool.lpToken.safeTransfer(address(msg.sender), _amount);
            pool.lpSupply = pool.lpSupply.sub(_amount);
        }
        user.rewardDebt = user.amount.mul(pool.accProtonPerShare).div(1e12);
        emit Withdraw(msg.sender, _pid, _amount);
    }

    /**
    Withdraw without caring about rewards. EMERGENCY ONLY.
    Resets user infos.
    Resets pool infos for the user (lpSupply)
    Transfers staked tokens to the user
    */
    function emergencyWithdraw(uint256 _pid) public nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        uint256 amount = user.amount;
        user.amount = 0;
        user.rewardDebt = 0;
        user.rewardLockedUp = 0;
        user.nextHarvestUntil = 0;
        pool.lpSupply = pool.lpSupply.sub(user.amount);
        pool.lpToken.safeTransfer(address(msg.sender), amount);
        emit EmergencyWithdraw(msg.sender, _pid, amount);
    }

    // Pay or lockup pending PROTOs.
    function payOrLockupPendingProton(uint256 _pid) internal {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];

        if (user.nextHarvestUntil == 0) {
            // Update nextHarvestTime for the user if it's set to 0
            user.nextHarvestUntil = block.timestamp.add(pool.harvestInterval);
        }

        uint256 pending = user.amount.mul(pool.accProtonPerShare).div(1e12).sub(user.rewardDebt);
        if (canHarvest(_pid, msg.sender)) {
            if (pending > 0 || user.rewardLockedUp > 0) {
                uint256 totalRewards = pending.add(user.rewardLockedUp);

                // Reset lockup
                totalLockedUpRewards = totalLockedUpRewards.sub(user.rewardLockedUp);
                user.rewardLockedUp = 0;
                user.nextHarvestUntil = block.timestamp.add(pool.harvestInterval);

                // Send rewards
                if(pool.isElectronRewards){
                    safeElectronTransfer(msg.sender, totalRewards);
                }
                else{
                    safeProtonTransfer(msg.sender, totalRewards);
                }
            }
        } else if (pending > 0) {
            user.rewardLockedUp = user.rewardLockedUp.add(pending);
            totalLockedUpRewards = totalLockedUpRewards.add(pending);
            emit RewardLockedUp(msg.sender, _pid, pending);
        }
    }

    // Safe proton transfer function, just in case if rounding error causes pool to not have enough PROTOs.
    function safeProtonTransfer(address _to, uint256 _amount) internal {
        uint256 protonBal = proton.balanceOf(address(this));
        bool transferSuccess = false;
        if (_amount > protonBal) {
            transferSuccess = proton.transfer(_to, protonBal);
        } else {
            transferSuccess = proton.transfer(_to, _amount);
        }
        require(transferSuccess, "safeProtonTransfer: Transfer failed");
    }

    // Safe electron transfer function, just in case if rounding error causes pool to not have enough ELCTs.
    function safeElectronTransfer(address _to, uint256 _amount) internal {
        uint256 electronBal = electron.balanceOf(address(this));
        bool transferSuccess = false;
        if (_amount > electronBal) {
            transferSuccess = electron.transfer(_to, electronBal);
        } else {
            transferSuccess = electron.transfer(_to, _amount);
        }
        require(transferSuccess, "safeElectronTransfer: Transfer failed");
    }

    function getPoolInfo(uint256 _pid) external view
        returns(address lpToken, uint256 allocPoint,
                uint256 lastRewardBlock, uint256 accProtonPerShare,
                uint256 depositFeeBP, uint256 harvestInterval,
                bool isElectronRewards) {
        return (
            address(poolInfo[_pid].lpToken),
            poolInfo[_pid].allocPoint,
            poolInfo[_pid].lastRewardBlock,
            poolInfo[_pid].accProtonPerShare,
            poolInfo[_pid].depositFeeBP,
            poolInfo[_pid].harvestInterval,
            poolInfo[_pid].isElectronRewards
        );
    }

    // Sets the dev address, can be changed only by the dev.
    function setDevAddress(address _devAddress) public {
        require(msg.sender == devAddress, "setDevAddress: FORBIDDEN");
        require(_devAddress != address(0), "setDevAddress: ZERO");
        devAddress = _devAddress;
        emit UpdatedDevAddress(msg.sender, _devAddress);
    }

    // Sets the fee address, can be changed only by the feeAddress.
    function setFeeAddress(address _feeAddress) public {
        require(msg.sender == feeAddress, "setFeeAddress: FORBIDDEN");
        require(_feeAddress != address(0), "setFeeAddress: ZERO");
        feeAddress = _feeAddress;
        emit UpdatedFeeAddress(msg.sender, _feeAddress);
    }

    // Update Emission Rate to control the emission per block (TimeLocked).
    function updateEmissionRate(uint256 _protonPerBlock) public onlyOwner {
        massUpdatePools();
        protonPerBlock = _protonPerBlock;
        emit UpdateEmissionRate(msg.sender, _protonPerBlock);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >= 0.6.12;

import "./libs/ProtofiERC20.sol";

/**
This is the contract of the primary token.

Features:
- 2% burn mechanism for every transaction.
- Ownable
- Strictly related to the second token
- You can use the second token to claim the primary token.
- Antiwhale,  can be set up only by operator

Owner --> Masterchef for farming features
Operator --> Team address that handles the antiwhales settings when needed
*/
contract ProtonToken is ProtofiERC20 {

    // Address to the secondary token
    address public electron;
    bool private _isElectronSetup = false;

    // Addresses that excluded from antiWhale
    mapping(address => bool) private _excludedFromAntiWhale;
    // Addresses that excluded from transfer fee
    mapping(address => bool) private _excludedFromTransferFee;

    // Max transfer amount rate in basis points. Eg: 50 - 0.5% of total supply (default the anti whale feature is turned off - set to 10000.)
    uint16 public maxTransferAmountRate = 10000;
    // Minimum transfer amount rate in basis points. Deserved for user trust, we can't block users to send this token.
    // maxTransferAmountRate cannot be lower than BASE_MIN_TRANSFER_AMOUNT_RATE
    uint16 public constant BASE_MAX_TRANSFER_AMOUNT_RATE = 100; // Cannot be changed, ever!
    // The operator can only update the Anti Whale Settings
    address private _operator;

    // Events
    event OperatorTransferred(address indexed previousOperator, address indexed newOperator);
    event MaxTransferAmountRateUpdated(address indexed operator, uint256 previousRate, uint256 newRate);

    constructor() public ProtofiERC20("Protofi Token", "PROTO"){

        // After initializing the token with the original constructor of ProtofiERC20
        // setup antiwhale variables.
        _operator = msg.sender;
        emit OperatorTransferred(address(0), _operator);

        _excludedFromAntiWhale[msg.sender] = true; // Original deployer address
        _excludedFromAntiWhale[address(0)] = true;
        _excludedFromAntiWhale[address(this)] = true;
        _excludedFromAntiWhale[BURN_ADDRESS] = true;
    }

    /**
    @dev similar to onlyOwner but used to handle the antiwhale side of the smart contract.
    In that way the ownership can be transferred to the MasterChef without preventing devs to modify
    antiwhale settings.
     */
    modifier onlyOperator() {
        require(_operator == msg.sender, "operator: caller is not the operator");
        _;
    }

    /**
    Exludes sender to send more than a certain amount of tokens given settings, if the
    sender is not whitelisted!
     */
    modifier antiWhale(address sender, address recipient, uint256 amount) {
        if (maxTransferAmount() > 0) {
            if (
                _excludedFromAntiWhale[sender] == false
            ) {
                require(amount <= maxTransferAmount(), "PROTO::antiWhale: Transfer amount exceeds the maxTransferAmount");
            }
        }
        _;
    }

    /**
     * @dev Returns the max transfer amount.
     */
    function maxTransferAmount() public view returns (uint256) {
        return totalSupply().mul(maxTransferAmountRate).div(10000);
    }

    /**
     * @dev Update the max transfer amount rate.
     * Can only be called by the current operator.
     */
    function updateMaxTransferAmountRate(uint16 _maxTransferAmountRate) public onlyOperator {
        require(_maxTransferAmountRate <= 10000, "PROTO::updateMaxTransferAmountRate: Max transfer amount rate must not exceed the maximum rate.");
        require(_maxTransferAmountRate >= BASE_MAX_TRANSFER_AMOUNT_RATE, "PROTO::updateMaxTransferAmountRate: _maxTransferAmountRate should be at least _maxTransferAmountRate");
        emit MaxTransferAmountRateUpdated(msg.sender, maxTransferAmountRate, _maxTransferAmountRate);
        maxTransferAmountRate = _maxTransferAmountRate;
    }

    /**
     * @dev Returns the address is excluded from antiWhale or not.
     */
    function isExcludedFromAntiWhale(address _account) public view returns (bool) {
        return _excludedFromAntiWhale[_account];
    }

    /**
     * @dev Exclude or include an address from antiWhale.
     * Can only be called by the current operator.
     */
    function setExcludedFromAntiWhale(address _account, bool _excluded) public onlyOperator {
        _excludedFromAntiWhale[_account] = _excluded;
    }

    /**
     * @dev Returns the address is excluded from transfer fee or not.
     */
    function isExcludedFromTransferFee(address _account) public view returns (bool) {
        return _excludedFromTransferFee[_account];
    }

    /**
     * @dev Exclude or include an address from transfer fee.
     * Can only be called by the current operator.
     */
    function setExcludedFromTransferFee(address _account, bool _excluded) public onlyOperator {
        _excludedFromTransferFee[_account] = _excluded;
    }

    /// @dev Throws if called by any account other than the owner or the secondary token
    modifier onlyOwnerOrElectron() {
        require(isOwner() || isElectron(), "caller is not the owner or electron");
        _;
    }

    /// @dev Returns true if the caller is the current owner.
    function isOwner() public view returns (bool) {
        return msg.sender == owner();
    }

    /// @dev Returns true if the caller is electron contracts.
    function isElectron() internal view returns (bool) {
        return msg.sender == address(electron);
    }

    /// @dev Sets the secondary token address.
    function setupElectron(address _electron) external onlyOwner{
        require(!_isElectronSetup, "The Electron token address has already been set up. No one can change it anymore.");
        electron = _electron;
        _isElectronSetup = true;
    }

    /**
    @notice Creates `_amount` token to `_to`. Must only be called by the masterchef or
    by the secondary token(during swap)
    */
    function mint(address _to, uint256 _amount) external virtual override onlyOwnerOrElectron  {
        _mint(_to, _amount);
    }

    /// @dev overrides transfer function to meet tokenomics of PROTO
    function _transfer(address sender, address recipient, uint256 amount) internal virtual override antiWhale(sender, recipient, amount) {
        require(amount > 0, "amount 0");

        if (recipient == BURN_ADDRESS) {
            // Burn all the amount
            super._burn(sender, amount);
        } else if (_excludedFromTransferFee[sender] || _excludedFromTransferFee[recipient]){
            // Transfer all the amount
            super._transfer(sender, recipient, amount);
        } else {
            // 1.8% of every transfer burnt
            uint256 burnAmount = amount.mul(18).div(1000);
            // 98.2% of transfer sent to recipient
            uint256 sendAmount = amount.sub(burnAmount);
            require(amount == sendAmount + burnAmount, "PROTO::transfer: Burn value invalid");

            super._burn(sender, burnAmount);
            super._transfer(sender, recipient, sendAmount);
            amount = sendAmount;
        }
    }

    /**
     * @dev Transfers operator of the contract to a new account (`newOperator`).
     * Can only be called by the current operator.
     */
    function transferOperator(address newOperator) public onlyOperator {
        require(newOperator != address(0), "ProtonToken::transferOperator: new operator is the zero address");
        emit OperatorTransferred(_operator, newOperator);
        _operator = newOperator;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >= 0.6.12;

interface IMoneyPot {
    function isDividendsToken(address _tokenAddr) external view returns (bool);
    function getRegisteredTokenLength() external view returns (uint256);
    function depositRewards(address _token, uint256 _amount) external;
    function getRegisteredToken(uint256 index) external view returns (address);
    function updateElectronHolder(address _electronHolder) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >= 0.6.12;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/GSN/Context.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";

/*
 * @dev Implementation of the {IERC20} interface.
 * This implementation is a copy of @pancakeswap/pancake-swap-lib/contracts/token/ERC20/ERC20.sol
 * with a burn supply management.
 */
contract ProtofiERC20 is Context, IERC20, Ownable {
    using SafeMath for uint256;
    using Address for address;

    address public constant BURN_ADDRESS = 0x000000000000000000000000000000000000dEaD;

    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;
    uint256 private _burnSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name, string memory symbol) public {
        _name = name;
        _symbol = symbol;
        _decimals = 18;
    }

    /**
     * @dev Returns the bep token owner.
     */
    function getOwner() external view returns (address) {
        return owner();
    }

    /**
     * @dev Returns the token name.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the token decimals.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }

    /**
     * @dev Returns the token symbol.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {ERC20-totalSupply}.
     */
    function totalSupply() public override view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {ERC20-totalSupply}.
     */
    function burnSupply() public view returns (uint256) {
        return _burnSupply;
    }

    /**
     * @dev See {ERC20-balanceOf}.
     */
    function balanceOf(address account) public override view returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {ERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {ERC20-allowance}.
     */
    function allowance(address owner, address spender) public override view returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {ERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {ERC20-transferFrom}.
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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance")
        );
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {ERC20-approve}.
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
     * problems described in {ERC20-approve}.
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
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero")
        );
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
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    function mint(address _to, uint256 _amount) external virtual onlyOwner{
        _mint(_to, _amount);
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
        require(account != BURN_ADDRESS, "ERC20: burn from the zero address");

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        _burnSupply = _burnSupply.add(amount);
        emit Transfer(account, BURN_ADDRESS, amount);
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
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`.`amount` is then deducted
     * from the caller"s allowance.
     *
     * See {_burn} and {_approve}.
     */
    function _burnFrom(address account, uint256 amount) internal {
        _burn(account, amount);
        _approve(
            account,
            _msgSender(),
            _allowances[account][_msgSender()].sub(amount, "ERC20: burn amount exceeds allowance")
        );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../GSN/Context.sol";
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
    constructor () internal {
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
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
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
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
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
     *
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
     *
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
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
     *
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
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
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
abstract contract ReentrancyGuard {
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

    constructor () internal {
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
}

{
  "remappings": [],
  "optimizer": {
    "enabled": true,
    "runs": 999999
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