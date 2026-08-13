// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma abicoder v2;

import "IERC20.sol";
import "SafeCast.sol";
import "Initializable.sol";

import "IOracleMaster.sol";
import "ILedgerFactory.sol";
import "ILedger.sol";
import "IController.sol";
import "IAuthManager.sol";
import "IWithdrawal.sol";

import "stKSM.sol";


contract Lido is stKSM, Initializable {
    using SafeCast for uint256;

    // Records a deposit made by a user
    event Deposited(address indexed sender, uint256 amount);

    // Created redeem order
    event Redeemed(address indexed receiver, uint256 amount);

    // Claimed vKSM tokens back
    event Claimed(address indexed receiver, uint256 amount);

    // Fee was updated
    event FeeSet(uint16 fee, uint16 feeOperatorsBP, uint16 feeTreasuryBP,  uint16 feeDevelopersBP);

    // Rewards distributed
    event Rewards(address ledger, uint256 rewards, uint256 balance);

    // Losses distributed
    event Losses(address ledger, uint256 losses, uint256 balance);

    // Added new ledger
    event LedgerAdd(
        address addr,
        bytes32 stashAccount,
        bytes32 controllerAccount
    );

    // Ledger removed
    event LedgerRemove(
        address addr
    );

    // Ledger disabled
    event LedgerDisable(
        address addr
    );

    // Ledger paused
    event LedgerPaused(
        address addr
    );

    // Ledger resumed
    event LedgerResumed(
        address addr
    );

    // sum of all deposits and rewards
    uint256 public fundRaisedBalance;

    // haven't executed buffrered deposits
    uint256 public bufferedDeposits;

    // haven't executed buffrered redeems
    uint256 public bufferedRedeems;

    // Ledger target stakes
    mapping(address => uint256) public ledgerStake;

    // Ledger borrow
    mapping(address => uint256) public ledgerBorrow;

    // Disabled ledgers
    address[] private disabledLedgers;

    // Enabled ledgers
    address[] private enabledLedgers;

    // Cap for deposits for v1
    uint256 public depositCap;

    // vKSM precompile
    IERC20 private VKSM;

    // controller
    address private CONTROLLER;

    // auth manager contract address
    address public AUTH_MANAGER;

    // Maximum number of ledgers
    uint256 private MAX_LEDGERS_AMOUNT;

    // oracle master contract
    address public ORACLE_MASTER;

    // relay spec
    Types.RelaySpec private RELAY_SPEC;

    // developers fund
    address private developers;

    // treasury fund
    address private treasury;

    // ledger beacon
    address public LEDGER_BEACON;

    // ledger factory
    address private LEDGER_FACTORY;

    // withdrawal contract
    address private WITHDRAWAL;

    // Max allowable difference for oracle reports
    uint128 public MAX_ALLOWABLE_DIFFERENCE;

    // Ledger address by stash account id
    mapping(bytes32 => address) private ledgerByStash;

    // Map to check ledger existence by address
    mapping(address => bool) private ledgerByAddress;

    // Map to check ledger paused to redeem state
    mapping(address => bool) private pausedledgers;

    /* fee interest in basis points.
    It's packed uint256 consist of three uint16 (total_fee, treasury_fee, developers_fee).
    where total_fee = treasury_fee + developers_fee + 3000 (3% operators fee)
    */
    Types.Fee private FEE;

    // default interest value in base points.
    uint16 internal constant DEFAULT_DEVELOPERS_FEE = 200;
    uint16 internal constant DEFAULT_OPERATORS_FEE = 0;
    uint16 internal constant DEFAULT_TREASURY_FEE = 800;

    // Missing member index
    uint256 internal constant MEMBER_NOT_FOUND = type(uint256).max;

    // Spec manager role
    bytes32 internal constant ROLE_SPEC_MANAGER = keccak256("ROLE_SPEC_MANAGER");

    // Beacon manager role
    bytes32 internal constant ROLE_BEACON_MANAGER = keccak256("ROLE_BEACON_MANAGER");

    // Pause manager role
    bytes32 internal constant ROLE_PAUSE_MANAGER = keccak256("ROLE_PAUSE_MANAGER");

    // Fee manager role
    bytes32 internal constant ROLE_FEE_MANAGER = keccak256("ROLE_FEE_MANAGER");

    // Ledger manager role
    bytes32 internal constant ROLE_LEDGER_MANAGER = keccak256("ROLE_LEDGER_MANAGER");

    // Stake manager role
    bytes32 internal constant ROLE_STAKE_MANAGER = keccak256("ROLE_STAKE_MANAGER");

    // Treasury manager role
    bytes32 internal constant ROLE_TREASURY = keccak256("ROLE_SET_TREASURY");

    // Developers address change role
    bytes32 internal constant ROLE_DEVELOPERS = keccak256("ROLE_SET_DEVELOPERS");

    // Allow function calls only from member with specific role
    modifier auth(bytes32 role) {
        require(IAuthManager(AUTH_MANAGER).has(role, msg.sender), "LIDO: UNAUTHORIZED");
        _;
    }

    /**
    * @notice Initialize lido contract.
    * @param _authManager - auth manager contract address
    * @param _vKSM - vKSM contract address
    * @param _controller - relay controller address
    * @param _developers - devs address
    * @param _treasury - treasury address
    * @param _oracleMaster - oracle master address
    * @param _withdrawal - withdrawal address
    * @param _depositCap - cap for deposits
    * @param _maxAllowableDifference - max allowable difference for oracle reports
    */
    function initialize(
        address _authManager,
        address _vKSM,
        address _controller,
        address _developers,
        address _treasury,
        address _oracleMaster,
        address _withdrawal,
        uint256 _depositCap,
        uint128 _maxAllowableDifference
    ) external initializer {
        require(_depositCap > 0, "LIDO: ZERO_CAP");
        require(_vKSM != address(0), "LIDO: INCORRECT_VKSM_ADDRESS");
        require(_oracleMaster != address(0), "LIDO: INCORRECT_ORACLE_MASTER_ADDRESS");
        require(_withdrawal != address(0), "LIDO: INCORRECT_WITHDRAWAL_ADDRESS");
        require(_authManager != address(0), "LIDO: INCORRECT_AUTHMANAGER_ADDRESS");
        require(_controller != address(0), "LIDO: INCORRECT_CONTROLLER_ADDRESS");

        VKSM = IERC20(_vKSM);
        CONTROLLER = _controller;
        AUTH_MANAGER = _authManager;

        depositCap = _depositCap;

        MAX_LEDGERS_AMOUNT = 200;
        Types.Fee memory _fee;
        _fee.total = DEFAULT_OPERATORS_FEE + DEFAULT_DEVELOPERS_FEE + DEFAULT_TREASURY_FEE;
        _fee.operators = DEFAULT_OPERATORS_FEE;
        _fee.developers = DEFAULT_DEVELOPERS_FEE;
        _fee.treasury = DEFAULT_TREASURY_FEE;
        FEE = _fee;

        treasury = _treasury;
        developers =_developers;

        ORACLE_MASTER = _oracleMaster;
        IOracleMaster(ORACLE_MASTER).setLido(address(this));

        WITHDRAWAL = _withdrawal;
        IWithdrawal(WITHDRAWAL).setStKSM(address(this));

        MAX_ALLOWABLE_DIFFERENCE = _maxAllowableDifference;
    }

    /**
    * @notice Set treasury address to '_treasury'
    */
    function setTreasury(address _treasury) external auth(ROLE_TREASURY) {
        require(_treasury != address(0), "LIDO: INCORRECT_TREASURY_ADDRESS");
        treasury = _treasury;
    }

    /**
    * @notice Set deposit cap to new value
    */
    function setDepositCap(uint256 _depositCap) external auth(ROLE_PAUSE_MANAGER) {
        require(_depositCap > 0, "LIDO: INCORRECT_NEW_CAP");
        depositCap = _depositCap;
    }

    /**
    * @notice Set ledger beacon address to '_ledgerBeacon'
    */
    function setLedgerBeacon(address _ledgerBeacon) external auth(ROLE_BEACON_MANAGER) {
        require(_ledgerBeacon != address(0), "LIDO: INCORRECT_BEACON_ADDRESS");
        LEDGER_BEACON = _ledgerBeacon;
    }

    function setMaxAllowableDifference(uint128 _maxAllowableDifference) external auth(ROLE_BEACON_MANAGER) {
        require(_maxAllowableDifference > 0, "LIDO: INCORRECT_MAX_ALLOWABLE_DIFFERENCE");
        MAX_ALLOWABLE_DIFFERENCE = _maxAllowableDifference;
    }

    /**
    * @notice Set ledger factory address to '_ledgerFactory'
    */
    function setLedgerFactory(address _ledgerFactory) external auth(ROLE_BEACON_MANAGER) {
        require(_ledgerFactory != address(0), "LIDO: INCORRECT_FACTORY_ADDRESS");
        LEDGER_FACTORY = _ledgerFactory;
    }

    /**
    * @notice Set developers address to '_developers'
    */
    function setDevelopers(address _developers) external auth(ROLE_DEVELOPERS) {
        require(_developers != address(0), "LIDO: INCORRECT_DEVELOPERS_ADDRESS");
        developers = _developers;
    }

    /**
    * @notice Set relay chain spec, allowed to call only by ROLE_SPEC_MANAGER
    * @dev if some params are changed function will iterate over oracles and ledgers, be careful
    * @param _relaySpec - new relaychain spec
    */
    function setRelaySpec(Types.RelaySpec calldata _relaySpec) external auth(ROLE_SPEC_MANAGER) {
        require(_relaySpec.maxValidatorsPerLedger > 0, "LIDO: BAD_MAX_VALIDATORS_PER_LEDGER");
        require(_relaySpec.maxUnlockingChunks > 0, "LIDO: BAD_MAX_UNLOCKING_CHUNKS");

        RELAY_SPEC = _relaySpec;

        _updateLedgerRelaySpecs(_relaySpec.minNominatorBalance, _relaySpec.ledgerMinimumActiveBalance, _relaySpec.maxUnlockingChunks);
    }

    /**
    * @notice Set new lido fee, allowed to call only by ROLE_FEE_MANAGER
    * @param _feeOperators - Operators percentage in basis points. It's always 3%
    * @param _feeTreasury - Treasury fund percentage in basis points
    * @param _feeDevelopers - Developers percentage in basis points
    */
    function setFee(uint16 _feeOperators, uint16 _feeTreasury,  uint16 _feeDevelopers) external auth(ROLE_FEE_MANAGER) {
        Types.Fee memory _fee;
        _fee.total = _feeTreasury + _feeOperators + _feeDevelopers;
        require(_fee.total <= 10000 && (_feeTreasury > 0 || _feeDevelopers > 0) && _feeOperators < 10000, "LIDO: FEE_DONT_ADD_UP");

        emit FeeSet(_fee.total, _feeOperators, _feeTreasury, _feeDevelopers);

        _fee.developers = _feeDevelopers;
        _fee.operators = _feeOperators;
        _fee.treasury = _feeTreasury;
        FEE = _fee;
    }

    /**
    * @notice Return unbonded tokens amount for user
    * @param _holder - user account for whom need to calculate unbonding
    * @return waiting - amount of tokens which are not unbonded yet
    * @return unbonded - amount of token which unbonded and ready to claim
    */
    function getUnbonded(address _holder) external view returns (uint256 waiting, uint256 unbonded) {
        uint256 waitingToUnbonding = 0;
        uint256 readyToClaim = 0;

        (waitingToUnbonding, readyToClaim) = IWithdrawal(WITHDRAWAL).getRedeemStatus(_holder);

        return (waitingToUnbonding, readyToClaim);
    }

    /**
    * @notice Return relay chain stash account addresses
    * @return Array of bytes32 relaychain stash accounts
    */
    function getStashAccounts() public view returns (bytes32[] memory) {
        bytes32[] memory _stashes = new bytes32[](enabledLedgers.length + disabledLedgers.length);

        for (uint i = 0; i < enabledLedgers.length; i++) {
            _stashes[i] = bytes32(ILedger(enabledLedgers[i]).stashAccount());
        }

        for (uint i = 0; i < disabledLedgers.length; i++) {
            _stashes[enabledLedgers.length + i] = bytes32(ILedger(disabledLedgers[i]).stashAccount());
        }
        return _stashes;
    }

    /**
    * @notice Return ledger contract addresses
    * @dev Each ledger contract linked with single stash account on the relaychain side
    * @return Array of ledger contract addresses
    */
    function getLedgerAddresses() public view returns (address[] memory) {
        address[] memory _ledgers = new address[](enabledLedgers.length + disabledLedgers.length);

        for (uint i = 0; i < enabledLedgers.length; i++) {
            _ledgers[i] = enabledLedgers[i];
        }

        for (uint i = 0; i < disabledLedgers.length; i++) {
            _ledgers[enabledLedgers.length + i] = disabledLedgers[i];
        }

        return _ledgers;
    }

    /**
    * @notice Return ledger address by stash account id
    * @dev If ledger not found function returns ZERO address
    * @param _stashAccount - relaychain stash account id
    * @return Linked ledger contract address
    */
    function findLedger(bytes32 _stashAccount) external view returns (address) {
        return ledgerByStash[_stashAccount];
    }

    /**
    * @notice Returns total fee basis points
    */
    function getFee() external view returns (uint16){
        return FEE.total;
    }

    /**
    * @notice Returns all fees basis points
    */
    function getAllFees() external view returns (Types.Fee memory){
        return FEE;
    }

    /**
    * @notice Stop pool routine operations (deposit, redeem, claimUnbonded),
    *         allowed to call only by ROLE_PAUSE_MANAGER
    */
    function pause() external auth(ROLE_PAUSE_MANAGER) {
        _pause();
    }

    /**
    * @notice Resume pool routine operations (deposit, redeem, claimUnbonded),
    *         allowed to call only by ROLE_PAUSE_MANAGER
    */
    function resume() external auth(ROLE_PAUSE_MANAGER) {
        _unpause();
    }

    /**
    * @notice Add new ledger, allowed to call only by ROLE_LEDGER_MANAGER
    * @dev That function deploys new ledger for provided stash account
    *      Also method triggers rebalancing stakes accross ledgers,
           recommended to carefully calculate share value to avoid significant rebalancing.
    * @param _stashAccount - relaychain stash account id
    * @param _controllerAccount - controller account id for given stash
    * @return created ledger address
    */
    function addLedger(
        bytes32 _stashAccount,
        bytes32 _controllerAccount,
        uint16 _index
    )
        external
        auth(ROLE_LEDGER_MANAGER)
        returns(address)
    {
        require(LEDGER_BEACON != address(0), "LIDO: UNSPECIFIED_LEDGER_BEACON");
        require(LEDGER_FACTORY != address(0), "LIDO: UNSPECIFIED_LEDGER_FACTORY");
        require(ORACLE_MASTER != address(0), "LIDO: NO_ORACLE_MASTER");
        require(enabledLedgers.length + disabledLedgers.length < MAX_LEDGERS_AMOUNT, "LIDO: LEDGERS_POOL_LIMIT");
        require(ledgerByStash[_stashAccount] == address(0), "LIDO: STASH_ALREADY_EXISTS");

        address ledger = ILedgerFactory(LEDGER_FACTORY).createLedger( 
            _stashAccount,
            _controllerAccount,
            address(VKSM),
            CONTROLLER,
            RELAY_SPEC.minNominatorBalance,
            RELAY_SPEC.ledgerMinimumActiveBalance,
            RELAY_SPEC.maxUnlockingChunks
        );

        enabledLedgers.push(ledger);
        ledgerByStash[_stashAccount] = ledger;
        ledgerByAddress[ledger] = true;

        IOracleMaster(ORACLE_MASTER).addLedger(ledger);

        IController(CONTROLLER).newSubAccount(_index, _stashAccount, ledger);

        emit LedgerAdd(ledger, _stashAccount, _controllerAccount);
        return ledger;
    }

    /**
    * @notice Disable ledger, allowed to call only by ROLE_LEDGER_MANAGER
    * @dev That method put ledger to "draining" mode, after ledger drained it can be removed
    * @param _ledgerAddress - target ledger address
    */
    function disableLedger(address _ledgerAddress) external auth(ROLE_LEDGER_MANAGER) {
        _disableLedger(_ledgerAddress);
    }

    /**
    * @notice Disable ledger and pause all redeems for that ledger, allowed to call only by ROLE_LEDGER_MANAGER
    * @dev That method pause all stake changes for ledger
    * @param _ledgerAddress - target ledger address
    */
    function emergencyPauseLedger(address _ledgerAddress) external auth(ROLE_LEDGER_MANAGER) {
        _disableLedger(_ledgerAddress);
        pausedledgers[_ledgerAddress] = true;
        emit LedgerPaused(_ledgerAddress);
    }

    /**
    * @notice Allow redeems from paused ledger, allowed to call only by ROLE_LEDGER_MANAGER
    * @param _ledgerAddress - target ledger address
    */
    function resumeLedger(address _ledgerAddress) external auth(ROLE_LEDGER_MANAGER) {
        require(pausedledgers[_ledgerAddress], "LIDO: LEDGER_NOT_PAUSED");
        delete pausedledgers[_ledgerAddress];
        emit LedgerResumed(_ledgerAddress);
    }

    /**
    * @notice Remove ledger, allowed to call only by ROLE_LEDGER_MANAGER
    * @dev That method cannot be executed for running ledger, so need to drain funds
    * @param _ledgerAddress - target ledger address
    */
    function removeLedger(address _ledgerAddress) external auth(ROLE_LEDGER_MANAGER) {
        require(ledgerByAddress[_ledgerAddress], "LIDO: LEDGER_NOT_FOUND");
        require(ledgerStake[_ledgerAddress] == 0, "LIDO: LEDGER_HAS_NON_ZERO_STAKE");
        uint256 ledgerIdx = _findDisabledLedger(_ledgerAddress);
        require(ledgerIdx != type(uint256).max, "LIDO: LEDGER_NOT_DISABLED");

        ILedger ledger = ILedger(_ledgerAddress);
        require(ledger.isEmpty(), "LIDO: LEDGER_IS_NOT_EMPTY");

        address lastLedger = disabledLedgers[disabledLedgers.length - 1];
        disabledLedgers[ledgerIdx] = lastLedger;
        disabledLedgers.pop();

        delete ledgerByAddress[_ledgerAddress];
        delete ledgerByStash[ledger.stashAccount()];

        if (pausedledgers[_ledgerAddress]) {
            delete pausedledgers[_ledgerAddress];
        }

        IOracleMaster(ORACLE_MASTER).removeLedger(_ledgerAddress);

        IController(CONTROLLER).deleteSubAccount(_ledgerAddress);

        emit LedgerRemove(_ledgerAddress);
    }

    /**
    * @notice Nominate on behalf of gived stash account, allowed to call only by ROLE_STAKE_MANAGER
    * @dev Method spawns xcm call to relaychain
    * @param _stashAccount - target stash account id
    * @param _validators - validators set to be nominated
    */
    function nominate(bytes32 _stashAccount, bytes32[] calldata _validators) external auth(ROLE_STAKE_MANAGER) {
        require(ledgerByStash[_stashAccount] != address(0),  "LIDO: UNKNOWN_STASH_ACCOUNT");
        require(_validators.length <= RELAY_SPEC.maxValidatorsPerLedger, "LIDO: VALIDATORS_AMOUNT_TOO_BIG");

        ILedger(ledgerByStash[_stashAccount]).nominate(_validators);
    }

    /**
    * @notice Deposit vKSM tokens to the pool and recieve stKSM(liquid staked tokens) instead.
              User should approve tokens before executing this call.
    * @dev Method accoumulate vKSMs on contract
    * @param _amount - amount of vKSM tokens to be deposited
    */
    function deposit(uint256 _amount) external whenNotPaused returns (uint256) {
        require(fundRaisedBalance + _amount < depositCap, "LIDO: DEPOSITS_EXCEED_CAP");

        VKSM.transferFrom(msg.sender, address(this), _amount);

        uint256 shares = _submit(_amount);

        emit Deposited(msg.sender, _amount);

        return shares;
    }

    /**
    * @notice Create request to redeem vKSM in exchange of stKSM. stKSM will be instantly burned and
              created claim order, (see `getUnbonded` method).
              User can have up to 20 redeem requests in parallel.
    * @param _amount - amount of stKSM tokens to be redeemed
    */
    function redeem(uint256 _amount) external whenNotPaused {
        uint256 _shares = getSharesByPooledKSM(_amount);
        require(_shares > 0, "LIDO: AMOUNT_TOO_LOW");
        require(_shares <= _sharesOf(msg.sender), "LIDO: REDEEM_AMOUNT_EXCEEDS_BALANCE");

        _burnShares(msg.sender, _shares);
        fundRaisedBalance -= _amount;
        bufferedRedeems += _amount;

        IWithdrawal(WITHDRAWAL).redeem(msg.sender, _amount);

        // emit event about burning (compatible with ERC20)
        emit Transfer(msg.sender, address(0), _amount);

        // lido event about redeemed
        emit Redeemed(msg.sender, _amount);
    }

    /**
    * @notice Claim all unbonded tokens at this point of time. Executed redeem requests will be removed
              and approproate amount of vKSM transferred to calling account.
    */
    function claimUnbonded() external whenNotPaused {
        uint256 amount = IWithdrawal(WITHDRAWAL).claim(msg.sender);
        emit Claimed(msg.sender, amount);
    }

    /**
    * @notice Distribute rewards earned by ledger, allowed to call only by ledger
    */
    function distributeRewards(uint256 _totalRewards, uint256 _ledgerBalance) external {
        require(ledgerByAddress[msg.sender], "LIDO: NOT_FROM_LEDGER");

        Types.Fee memory _fee = FEE;

        // it's `feeDevelopers` + `feeTreasure`
        uint256 _feeDevTreasure = uint256(_fee.developers + _fee.treasury);
        assert(_feeDevTreasure>0);

        fundRaisedBalance += _totalRewards;
        ledgerStake[msg.sender] += _totalRewards;
        ledgerBorrow[msg.sender] += _totalRewards;

        uint256 _rewards = _totalRewards * _feeDevTreasure / uint256(10000 - _fee.operators);
        uint256 denom = _getTotalPooledKSM()  - _rewards;
        uint256 shares2mint = _getTotalPooledKSM();
        if (denom > 0) shares2mint = _rewards * _getTotalShares() / denom;

        _mintShares(treasury, shares2mint);

        uint256 _devShares = shares2mint *  uint256(_fee.developers) / _feeDevTreasure;
        _transferShares(treasury, developers, _devShares);
        _emitTransferAfterMintingShares(developers, _devShares);
        _emitTransferAfterMintingShares(treasury, shares2mint - _devShares);

        emit Rewards(msg.sender, _totalRewards, _ledgerBalance);
    }

    /**
    * @notice Distribute lossed by ledger, allowed to call only by ledger
    */
    function distributeLosses(uint256 _totalLosses, uint256 _ledgerBalance) external {
        require(ledgerByAddress[msg.sender], "LIDO: NOT_FROM_LEDGER");

        uint256 withdrawalBalance = IWithdrawal(WITHDRAWAL).totalBalanceForLosses();
        // lidoPart = _totalLosses * lido_xcKSM_balance / sum_xcKSM_balance
        uint256 lidoPart = (_totalLosses * fundRaisedBalance) / (fundRaisedBalance + withdrawalBalance);

        fundRaisedBalance -= lidoPart;
        if ((_totalLosses - lidoPart) > 0) {
            IWithdrawal(WITHDRAWAL).ditributeLosses(_totalLosses - lidoPart);
        }

        // edge case when loss can be more than stake
        ledgerStake[msg.sender] -= ledgerStake[msg.sender] >= _totalLosses ? _totalLosses : ledgerStake[msg.sender];
        ledgerBorrow[msg.sender] -= _totalLosses;

        emit Losses(msg.sender, _totalLosses, _ledgerBalance);
    }

    /**
    * @notice Transfer vKSM from ledger to LIDO. Can be called only from ledger
    * @param _amount - amount of vKSM that should be transfered
    * @param _excess - excess of vKSM that was transfered
    */
    function transferFromLedger(uint256 _amount, uint256 _excess) external {
        require(ledgerByAddress[msg.sender], "LIDO: NOT_FROM_LEDGER");

        if (_excess > 0) { // some donations
            fundRaisedBalance += _excess; //just distribute it as rewards
            bufferedDeposits += _excess;
            VKSM.transferFrom(msg.sender, address(this), _excess);
        }

        ledgerBorrow[msg.sender] -= _amount;
        VKSM.transferFrom(msg.sender, WITHDRAWAL, _amount);
    }

    /**
    * @notice Transfer vKSM from ledger to LIDO. Can be called only from ledger
    * @param _amount - amount of transfered vKSM
    */
    function transferFromLedger(uint256 _amount) external {
        require(ledgerByAddress[msg.sender], "LIDO: NOT_FROM_LEDGER");

        if (_amount > ledgerBorrow[msg.sender]) { // some donations
            uint256 excess = _amount - ledgerBorrow[msg.sender];
            fundRaisedBalance += excess; //just distribute it as rewards
            bufferedDeposits += excess;
            ledgerBorrow[msg.sender] = 0;
            VKSM.transferFrom(msg.sender, address(this), excess);
            VKSM.transferFrom(msg.sender, WITHDRAWAL, _amount - excess);
        }
        else {
            ledgerBorrow[msg.sender] -= _amount;
            VKSM.transferFrom(msg.sender, WITHDRAWAL, _amount);
        }
    }

    /**
    * @notice Transfer vKSM from LIDO to ledger. Can be called only from ledger
    * @param _amount - amount of transfered vKSM
    */
    function transferToLedger(uint256 _amount) external {
        require(ledgerByAddress[msg.sender], "LIDO: NOT_FROM_LEDGER");
        require(ledgerBorrow[msg.sender] + _amount <= ledgerStake[msg.sender], "LIDO: LEDGER_NOT_ENOUGH_STAKE");

        ledgerBorrow[msg.sender] += _amount;
        VKSM.transfer(msg.sender, _amount);
    }

    /**
    * @notice Flush stakes, allowed to call only by oracle master
    * @dev This method distributes buffered stakes between ledgers by soft manner
    */
    function flushStakes() external {
        require(msg.sender == ORACLE_MASTER, "LIDO: NOT_FROM_ORACLE_MASTER");

        IWithdrawal(WITHDRAWAL).newEra();
        _softRebalanceStakes();
    }

    /**
    * @notice Rebalance stake accross ledgers by soft manner.
    */
    function _softRebalanceStakes() internal {
        if (bufferedDeposits > 0 || bufferedRedeems > 0) {
            // first try to distribute redeems accross disabled ledgers
            if (disabledLedgers.length > 0 && bufferedRedeems > 0) {
                bufferedRedeems = _processDisabledLedgers(bufferedRedeems);
            }

            // NOTE: if we have deposits and redeems in one era we need to send all possible xcKSMs to Withdrawal
            if (bufferedDeposits > 0 && bufferedRedeems > 0) {
                uint256 maxImmediateTransfer = bufferedDeposits > bufferedRedeems ? bufferedRedeems : bufferedDeposits;
                bufferedDeposits -= maxImmediateTransfer;
                bufferedRedeems -= maxImmediateTransfer;
                VKSM.transfer(WITHDRAWAL, maxImmediateTransfer);
            }

            // distribute remaining stakes and redeems accross enabled
            if (enabledLedgers.length > 0) {
                int256 stake = bufferedDeposits.toInt256() - bufferedRedeems.toInt256();
                if (stake != 0) {
                    _processEnabled(stake);
                }
                bufferedDeposits = 0;
                bufferedRedeems = 0;
            }
        }
    }

    /**
    * @notice Spread redeems accross disabled ledgers
    * @return remainingRedeems - redeems amount which didn't distributed
    */
    function _processDisabledLedgers(uint256 redeems) internal returns(uint256 remainingRedeems) {
        uint256 disabledLength = disabledLedgers.length;
        assert(disabledLength > 0);

        uint256 stakesSum = 0;
        uint256 actualRedeems = 0;

        for (uint256 i = 0; i < disabledLength; ++i) {
            if (!pausedledgers[disabledLedgers[i]]) {
                stakesSum += ledgerStake[disabledLedgers[i]];
            }
        }

        if (stakesSum == 0) return redeems;

        for (uint256 i = 0; i < disabledLength; ++i) {
            if (!pausedledgers[disabledLedgers[i]]) {
                uint256 currentStake = ledgerStake[disabledLedgers[i]];
                uint256 decrement = redeems * currentStake / stakesSum;
                decrement = decrement > currentStake ? currentStake : decrement;
                ledgerStake[disabledLedgers[i]] = currentStake - decrement;
                actualRedeems += decrement;
            }
        }

        return redeems - actualRedeems;
    }

    /**
    * @notice Distribute stakes and redeems accross enabled ledgers with relaxation
    * @dev this function should never mix bond/unbond
    */
    function _processEnabled(int256 _stake) internal {
        uint256 ledgersLength = enabledLedgers.length;
        assert(ledgersLength > 0);

        int256[] memory diffs = new int256[](ledgersLength);
        address[] memory ledgersCache = new address[](ledgersLength);
        int256[] memory ledgerStakesCache = new int256[](ledgersLength);

        int256 activeDiffsSum = 0;
        int256 totalChange = 0;
        int256 preciseDiffSum = 0;

        {
            uint256 targetStake = getTotalPooledKSM() / ledgersLength;
            int256 diff = 0;
            for (uint256 i = 0; i < ledgersLength; ++i) {
                ledgersCache[i] = enabledLedgers[i];
                ledgerStakesCache[i] = int256(ledgerStake[ledgersCache[i]]);

                diff = int256(targetStake) - int256(ledgerStakesCache[i]);
                if (_stake * diff > 0) {
                    activeDiffsSum += diff;
                }
                diffs[i] = diff;
                preciseDiffSum += diff;
            }
        }

        if (preciseDiffSum == 0 || activeDiffsSum == 0) {
            return;
        }

        int8 direction = 1;
        if (activeDiffsSum < 0) {
            direction = -1;
            activeDiffsSum = -activeDiffsSum;
        }

        for (uint256 i = 0; i < ledgersLength; ++i) {
            diffs[i] *= direction;
            if (diffs[i] > 0) {
                int256 change = diffs[i] * _stake / activeDiffsSum;
                int256 newStake = ledgerStakesCache[i] + change;
                ledgerStake[ledgersCache[i]] = uint256(newStake);
                ledgerStakesCache[i] = newStake;
                totalChange += change;
            }
        }

        {
            int256 remaining = _stake - totalChange;
            if (remaining > 0) {
                // just add to first ledger
                ledgerStake[ledgersCache[0]] += uint256(remaining);
            }
            else if (remaining < 0) {
                for (uint256 i = 0; i < ledgersLength && remaining < 0; ++i) {
                    uint256 stake = uint256(ledgerStakesCache[i]);
                    if (stake > 0) {
                        uint256 decrement = stake > uint256(-remaining) ? uint256(-remaining) : stake;
                        ledgerStake[ledgersCache[i]] -= decrement;
                        remaining += int256(decrement);
                    }
                }
            }
        }
    }

    /**
    * @notice Set new minimum balance for ledger
    * @param _minNominatorBalance - new minimum nominator balance
    * @param _minimumBalance - new minimum active balance for ledger
    * @param _maxUnlockingChunks - new maximum unlocking chunks
    */
    function _updateLedgerRelaySpecs(uint128 _minNominatorBalance, uint128 _minimumBalance, uint256 _maxUnlockingChunks) internal {
        for (uint i = 0; i < enabledLedgers.length; i++) {
            ILedger(enabledLedgers[i]).setRelaySpecs(_minNominatorBalance, _minimumBalance, _maxUnlockingChunks);
        }

        for (uint i = 0; i < disabledLedgers.length; i++) {
            ILedger(disabledLedgers[i]).setRelaySpecs(_minNominatorBalance, _minimumBalance, _maxUnlockingChunks);
        }
    }

    /**
    * @notice Disable ledger
    * @dev That method put ledger to "draining" mode, after ledger drained it can be removed
    * @param _ledgerAddress - target ledger address
    */
    function _disableLedger(address _ledgerAddress) internal {
        require(ledgerByAddress[_ledgerAddress], "LIDO: LEDGER_NOT_FOUND");
        uint256 ledgerIdx = _findEnabledLedger(_ledgerAddress);
        require(ledgerIdx != type(uint256).max, "LIDO: LEDGER_NOT_ENABLED");

        address lastLedger = enabledLedgers[enabledLedgers.length - 1];
        enabledLedgers[ledgerIdx] = lastLedger;
        enabledLedgers.pop();

        disabledLedgers.push(_ledgerAddress);

        emit LedgerDisable(_ledgerAddress);
    }

    /**
    * @notice Process user deposit, mints stKSM and increase the pool buffer
    * @return amount of stKSM shares generated
    */
    function _submit(uint256 _deposit) internal returns (uint256) {
        address sender = msg.sender;

        require(_deposit != 0, "LIDO: ZERO_DEPOSIT");

        uint256 sharesAmount = getSharesByPooledKSM(_deposit);
        if (sharesAmount == 0) {
            // totalPooledKSM is 0: either the first-ever deposit or complete slashing
            // assume that shares correspond to KSM as 1-to-1
            sharesAmount = _deposit;
        }

        fundRaisedBalance += _deposit;
        bufferedDeposits += _deposit;
        _mintShares(sender, sharesAmount);

        _emitTransferAfterMintingShares(sender, sharesAmount);
        return sharesAmount;
    }


    /**
    * @notice Emits an {Transfer} event where from is 0 address. Indicates mint events.
    */
    function _emitTransferAfterMintingShares(address _to, uint256 _sharesAmount) internal {
        emit Transfer(address(0), _to, getPooledKSMByShares(_sharesAmount));
    }

    /**
    * @notice Returns amount of total pooled tokens by contract.
    * @return amount of pooled vKSM in contract
    */
    function _getTotalPooledKSM() internal view override returns (uint256) {
        return fundRaisedBalance;
    }

    /**
    * @notice Returns enabled ledger index by given address
    * @return enabled ledger index or uint256_max if not found
    */
    function _findEnabledLedger(address _ledgerAddress) internal view returns(uint256) {
        for (uint256 i = 0; i < enabledLedgers.length; ++i) {
            if (enabledLedgers[i] == _ledgerAddress) {
                return i;
            }
        }
        return type(uint256).max;
    }

    /**
    * @notice Returns disabled ledger index by given address
    * @return disabled ledger index or uint256_max if not found
    */
    function _findDisabledLedger(address _ledgerAddress) internal view returns(uint256) {
        for (uint256 i = 0; i < disabledLedgers.length; ++i) {
            if (disabledLedgers[i] == _ledgerAddress) {
                return i;
            }
        }
        return type(uint256).max;
    }
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

pragma solidity ^0.8.0;

/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafeCast {
    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value < 2**128, "SafeCast: value doesn\'t fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value < 2**64, "SafeCast: value doesn\'t fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value < 2**32, "SafeCast: value doesn\'t fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value < 2**16, "SafeCast: value doesn\'t fit in 16 bits");
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value < 2**8, "SafeCast: value doesn\'t fit in 8 bits");
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v3.1._
     */
    function toInt128(int256 value) internal pure returns (int128) {
        require(value >= -2**127 && value < 2**127, "SafeCast: value doesn\'t fit in 128 bits");
        return int128(value);
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v3.1._
     */
    function toInt64(int256 value) internal pure returns (int64) {
        require(value >= -2**63 && value < 2**63, "SafeCast: value doesn\'t fit in 64 bits");
        return int64(value);
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v3.1._
     */
    function toInt32(int256 value) internal pure returns (int32) {
        require(value >= -2**31 && value < 2**31, "SafeCast: value doesn\'t fit in 32 bits");
        return int32(value);
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v3.1._
     */
    function toInt16(int256 value) internal pure returns (int16) {
        require(value >= -2**15 && value < 2**15, "SafeCast: value doesn\'t fit in 16 bits");
        return int16(value);
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8) {
        require(value >= -2**7 && value < 2**7, "SafeCast: value doesn\'t fit in 8 bits");
        return int8(value);
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        require(value < 2**255, "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}

// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
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

interface IOracleMaster {
    function addLedger(address ledger) external;

    function removeLedger(address ledger) external;

    function getOracle(address ledger) view external returns (address);

    function eraId() view external returns (uint64);

    function setLido(address lido) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ILedgerFactory {
    function createLedger(
        bytes32 _stashAccount,
        bytes32 _controllerAccount,
        address _vKSM,
        address _controller,
        uint128 _minNominatorBalance,
        uint128 _minimumBalance,
        uint256 _maxUnlockingChunks
    ) external returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "Types.sol";

interface ILedger {
    function initialize(
        bytes32 _stashAccount,
        bytes32 controllerAccount,
        address vKSM,
        address controller,
        uint128 minNominatorBalance,
        address lido,
        uint128 _minimumBalance,
        uint256 _maxUnlockingChunks
    ) external;

    function pushData(uint64 eraId, Types.OracleData calldata staking) external;

    function nominate(bytes32[] calldata validators) external;

    function status() external view returns (Types.LedgerStatus);

    function isEmpty() external view returns (bool);

    function stashAccount() external view returns (bytes32);

    function totalBalance() external view returns (uint128);

    function setRelaySpecs(uint128 minNominatorBalance, uint128 minimumBalance, uint256 _maxUnlockingChunks) external;

    function cachedTotalBalance() external view returns (uint128);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface Types {
    struct Fee{
        uint16 total;
        uint16 operators;
        uint16 developers;
        uint16 treasury;
    }

    struct Stash {
        bytes32 stashAccount;
        uint64  eraId;
    }

    enum LedgerStatus {
        // bonded but not participate in staking
        Idle,
        // participate as nominator
        Nominator,
        // participate as validator
        Validator,
        // not bonded not participate in staking
        None
    }

    struct UnlockingChunk {
        uint128 balance;
        uint64 era;
    }

    struct OracleData {
        bytes32 stashAccount;
        bytes32 controllerAccount;
        LedgerStatus stakeStatus;
        // active part of stash balance
        uint128 activeBalance;
        // locked for stake stash balance.
        uint128 totalBalance;
        // totalBalance = activeBalance + sum(unlocked.balance)
        UnlockingChunk[] unlocking;
        uint32[] claimedRewards;
        // stash account balance. It includes locked (totalBalance) balance assigned
        // to a controller.
        uint128 stashBalance;
        // slashing spans for ledger
        uint32 slashingSpans;
    }

    struct RelaySpec {
        uint16 maxValidatorsPerLedger;
        uint128 minNominatorBalance;
        uint128 ledgerMinimumActiveBalance;
        uint256 maxUnlockingChunks;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


interface IController {
    function newSubAccount(uint16 index, bytes32 accountId, address paraAddress) external;

    function deleteSubAccount(address paraAddress) external;

    function nominate(bytes32[] calldata _validators) external;

    function bond(bytes32 controller, uint256 amount) external;

    function bondExtra(uint256 amount) external;

    function unbond(uint256 amount) external;

    function withdrawUnbonded(uint32 slashingSpans) external;

    function rebond(uint256 amount, uint256 unbondingChunks) external;

    function chill() external;

    function transferToParachain(uint256 amount) external;

    function transferToRelaychain(uint256 amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IAuthManager {
    function has(bytes32 role, address member) external view returns (bool);

    function add(bytes32 role, address member) external;

    function remove(bytes32 role, address member) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IWithdrawal {
    // total virtual xcKSM amount on contract
    function totalVirtualXcKSMAmount() external returns (uint256);

    // Set stKSM contract address, allowed to only once
    function setStKSM(address _stKSM) external;

    // Returns total virtual xcKSM balance of contract for which losses can be applied
    function totalBalanceForLosses() external view returns (uint256);

    // Burn pool shares from first element of queue and move index for allow claiming. After that add new batch
    function newEra() external;

    // Mint equal amount of pool shares for user. Adjust current amount of virtual xcKSM on Withdrawal contract.
    // Burn shares on LIDO side
    function redeem(address _from, uint256 _amount) external;

    // Returns available for claiming xcKSM amount for user
    function claim(address _holder) external returns (uint256);

    // Apply losses to current stKSM shares on this contract
    function ditributeLosses(uint256 _losses) external;

    // Check available for claim xcKSM balance for user
    function getRedeemStatus(address _holder) external view returns(uint256 _waiting, uint256 _available);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "IERC20.sol";
import "Pausable.sol";

abstract contract stKSM is IERC20, Pausable {

    /**
     * @dev stKSM balances are dynamic and are calculated based on the accounts' shares
     * and the total amount of KSM controlled by the protocol. Account shares aren't
     * normalized, so the contract also stores the sum of all shares to calculate
     * each account's token balance which equals to:
     *
     *   shares[account] * _getTotalPooledKSM() / _getTotalShares()
    */
    mapping (address => uint256) private shares;

    /**
     * @dev Allowances are nominated in tokens, not token shares.
     */
    mapping (address => mapping (address => uint256)) private allowances;

    /**
     * @dev Storage position used for holding the total amount of shares in existence.
     */
    uint256 internal totalShares;

    /**
     * @return the name of the token.
     */
    function name() public pure returns (string memory) {
        return "Liquid staked KSM";
    }

    /**
     * @return the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public pure returns (string memory) {
        return "stKSM";
    }

    /**
     * @return the number of decimals for getting user representation of a token amount.
     */
    function decimals() public pure returns (uint8) {
        return 12;
    }

    /**
     * @return the amount of tokens in existence.
     *
     * @dev Always equals to `_getTotalPooledKSM()` since token amount
     * is pegged to the total amount of KSM controlled by the protocol.
     */
    function totalSupply() public view override returns (uint256) {
        return _getTotalPooledKSM();
    }

    /**
     * @return the entire amount of KSMs controlled by the protocol.
     *
     * @dev The sum of all KSM balances in the protocol.
     */
    function getTotalPooledKSM() public view returns (uint256) {
        return _getTotalPooledKSM();
    }

    /**
     * @return the amount of tokens owned by the `_account`.
     *
     * @dev Balances are dynamic and equal the `_account`'s share in the amount of the
     * total KSM controlled by the protocol. See `sharesOf`.
     */
    function balanceOf(address _account) public view override returns (uint256) {
        return getPooledKSMByShares(_sharesOf(_account));
    }

    /**
     * @notice Moves `_amount` tokens from the caller's account to the `_recipient` account.
     *
     * @return a boolean value indicating whether the operation succeeded.
     * Emits a `Transfer` event.
     *
     * Requirements:
     *
     * - `_recipient` cannot be the zero address.
     * - the caller must have a balance of at least `_amount`.
     * - the contract must not be paused.
     *
     * @dev The `_amount` argument is the amount of tokens, not shares.
     */
    function transfer(address _recipient, uint256 _amount) public override returns (bool) {
        _transfer(msg.sender, _recipient, _amount);
        return true;
    }

    /**
     * @return the remaining number of tokens that `_spender` is allowed to spend
     * on behalf of `_owner` through `transferFrom`. This is zero by default.
     *
     * @dev This value changes when `approve` or `transferFrom` is called.
     */
    function allowance(address _owner, address _spender) public view override returns (uint256) {
        return allowances[_owner][_spender];
    }

    /**
     * @notice Sets `_amount` as the allowance of `_spender` over the caller's tokens.
     *
     * @return a boolean value indicating whether the operation succeeded.
     * Emits an `Approval` event.
     *
     * Requirements:
     *
     * - `_spender` cannot be the zero address.
     * - the contract must not be paused.
     *
     * @dev The `_amount` argument is the amount of tokens, not shares.
     */
    function approve(address _spender, uint256 _amount) public override returns (bool) {
        _approve(msg.sender, _spender, _amount);
        return true;
    }

    /**
     * @notice Moves `_amount` tokens from `_sender` to `_recipient` using the
     * allowance mechanism. `_amount` is then deducted from the caller's
     * allowance.
     *
     * @return a boolean value indicating whether the operation succeeded.
     *
     * Emits a `Transfer` event.
     * Emits an `Approval` event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `_sender` and `_recipient` cannot be the zero addresses.
     * - `_sender` must have a balance of at least `_amount`.
     * - the caller must have allowance for `_sender`'s tokens of at least `_amount`.
     * - the contract must not be paused.
     *
     * @dev The `_amount` argument is the amount of tokens, not shares.
     */
    function transferFrom(address _sender, address _recipient, uint256 _amount) public override returns (bool) {
        uint256 currentAllowance = allowances[_sender][msg.sender];
        require(currentAllowance >= _amount, "TRANSFER_AMOUNT_EXCEEDS_ALLOWANCE");

        _transfer(_sender, _recipient, _amount);
        _approve(_sender, msg.sender, currentAllowance -_amount);
        return true;
    }

    /**
     * @notice Atomically increases the allowance granted to `_spender` by the caller by `_addedValue`.
     *
     * This is an alternative to `approve` that can be used as a mitigation for
     * problems described in:
     * https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/IERC20.sol#L42
     * Emits an `Approval` event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `_spender` cannot be the the zero address.
     * - the contract must not be paused.
     */
    function increaseAllowance(address _spender, uint256 _addedValue) public returns (bool) {
        _approve(msg.sender, _spender, allowances[msg.sender][_spender] + _addedValue);
        return true;
    }

    /**
     * @notice Atomically decreases the allowance granted to `_spender` by the caller by `_subtractedValue`.
     *
     * This is an alternative to `approve` that can be used as a mitigation for
     * problems described in:
     * https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/IERC20.sol#L42
     * Emits an `Approval` event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `_spender` cannot be the zero address.
     * - `_spender` must have allowance for the caller of at least `_subtractedValue`.
     * - the contract must not be paused.
     */
    function decreaseAllowance(address _spender, uint256 _subtractedValue) public returns (bool) {
        uint256 currentAllowance = allowances[msg.sender][_spender];
        require(currentAllowance >= _subtractedValue, "DECREASED_ALLOWANCE_BELOW_ZERO");
        _approve(msg.sender, _spender, currentAllowance-_subtractedValue);
        return true;
    }

    /**
     * @return the total amount of shares in existence.
     *
     * @dev The sum of all accounts' shares can be an arbitrary number, therefore
     * it is necessary to store it in order to calculate each account's relative share.
     */
    function getTotalShares() public view returns (uint256) {
        return _getTotalShares();
    }

    /**
     * @return the amount of shares owned by `_account`.
     */
    function sharesOf(address _account) public view returns (uint256) {
        return _sharesOf(_account);
    }

    /**
     * @return the amount of shares that corresponds to `_ethAmount` protocol-controlled KSM.
     */
    function getSharesByPooledKSM(uint256 _amount) public view returns (uint256) {
        uint256 totalPooledKSM = _getTotalPooledKSM();
        if (totalPooledKSM == 0) {
            return 0;
        } else {
            return _amount * _getTotalShares() / totalPooledKSM;
        }
    }

    /**
     * @return the amount of KSM that corresponds to `_sharesAmount` token shares.
     */
    function getPooledKSMByShares(uint256 _sharesAmount) public view returns (uint256) {
        uint256 _totalShares = _getTotalShares();
        if (totalShares == 0) {
            return 0;
        } else {
            return _sharesAmount * _getTotalPooledKSM() / _totalShares;
        }
    }

    /**
     * @return the total amount (in wei) of KSM controlled by the protocol.
     * @dev This is used for calaulating tokens from shares and vice versa.
     * @dev This function is required to be implemented in a derived contract.
     */
    function _getTotalPooledKSM() internal view virtual returns (uint256);

    /**
     * @notice Moves `_amount` tokens from `_sender` to `_recipient`.
     * Emits a `Transfer` event.
     */
    function _transfer(address _sender, address _recipient, uint256 _amount) internal {
        uint256 _sharesToTransfer = getSharesByPooledKSM(_amount);
        _transferShares(_sender, _recipient, _sharesToTransfer);
        emit Transfer(_sender, _recipient, _amount);
    }

    /**
     * @notice Sets `_amount` as the allowance of `_spender` over the `_owner` s tokens.
     *
     * Emits an `Approval` event.
     *
     * Requirements:
     *
     * - `_owner` cannot be the zero address.
     * - `_spender` cannot be the zero address.
     * - the contract must not be paused.
     */
    function _approve(address _owner, address _spender, uint256 _amount) internal whenNotPaused {
        require(_owner != address(0), "APPROVE_FROM_ZERO_ADDRESS");
        require(_spender != address(0), "APPROVE_TO_ZERO_ADDRESS");

        allowances[_owner][_spender] = _amount;
        emit Approval(_owner, _spender, _amount);
    }

    /**
     * @return the total amount of shares in existence.
     */
    function _getTotalShares() internal view returns (uint256) {
        return totalShares;
    }

    /**
     * @return the amount of shares owned by `_account`.
     */
    function _sharesOf(address _account) internal view returns (uint256) {
        return shares[_account];
    }

    /**
     * @notice Moves `_sharesAmount` shares from `_sender` to `_recipient`.
     *
     * Requirements:
     *
     * - `_sender` cannot be the zero address.
     * - `_recipient` cannot be the zero address.
     * - `_sender` must hold at least `_sharesAmount` shares.
     * - the contract must not be paused.
     */
    function _transferShares(address _sender, address _recipient, uint256 _sharesAmount) internal whenNotPaused {
        require(_sender != address(0), "TRANSFER_FROM_THE_ZERO_ADDRESS");
        require(_recipient != address(0), "TRANSFER_TO_THE_ZERO_ADDRESS");

        uint256 currentSenderShares = shares[_sender];
        require(_sharesAmount <= currentSenderShares, "TRANSFER_AMOUNT_EXCEEDS_BALANCE");

        shares[_sender] = currentSenderShares - _sharesAmount;
        shares[_recipient] = shares[_recipient] + _sharesAmount;
    }

    /**
     * @notice Creates `_sharesAmount` shares and assigns them to `_recipient`, increasing the total amount of shares.
     * @dev This doesn't increase the token total supply.
     *
     * Requirements:
     *
     * - `_recipient` cannot be the zero address.
     * - the contract must not be paused.
     */
    function _mintShares(address _recipient, uint256 _sharesAmount) internal whenNotPaused returns (uint256 newTotalShares) {
        require(_recipient != address(0), "MINT_TO_THE_ZERO_ADDRESS");

        newTotalShares = _getTotalShares() + _sharesAmount;
        totalShares = newTotalShares;

        shares[_recipient] = shares[_recipient] + _sharesAmount;

        // Notice: we're not emitting a Transfer event from the zero address here since shares mint
        // works by taking the amount of tokens corresponding to the minted shares from all other
        // token holders, proportionally to their share. The total supply of the token doesn't change
        // as the result. This is equivalent to performing a send from each other token holder's
        // address to `address`, but we cannot reflect this as it would require sending an unbounded
        // number of events.
    }

    /**
     * @notice Destroys `_sharesAmount` shares from `_account`'s holdings, decreasing the total amount of shares.
     * @dev This doesn't decrease the token total supply.
     *
     * Requirements:
     *
     * - `_account` cannot be the zero address.
     * - `_account` must hold at least `_sharesAmount` shares.
     * - the contract must not be paused.
     */
    function _burnShares(address _account, uint256 _sharesAmount) internal whenNotPaused returns (uint256 newTotalShares) {
        require(_account != address(0), "BURN_FROM_THE_ZERO_ADDRESS");

        uint256 accountShares = shares[_account];
        require(_sharesAmount <= accountShares, "BURN_AMOUNT_EXCEEDS_BALANCE");

        newTotalShares = _getTotalShares() - _sharesAmount;
        totalShares = newTotalShares;

        shares[_account] = accountShares - _sharesAmount;

        // Notice: we're not emitting a Transfer event to the zero address here since shares burn
        // works by redistributing the amount of tokens corresponding to the burned shares between
        // all other token holders. The total supply of the token doesn't change as the result.
        // This is equivalent to performing a send from `address` to each other token holder address,
        // but we cannot reflect this as it would require sending an unbounded number of events.
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
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
    constructor () {
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
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}