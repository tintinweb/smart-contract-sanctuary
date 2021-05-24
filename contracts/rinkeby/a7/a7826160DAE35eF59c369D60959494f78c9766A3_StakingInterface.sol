// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.7.0;


import "NuCypherToken.sol";
import "StakingEscrow.sol";
import "PolicyManager.sol";
import "WorkLock.sol";


/**
* @notice Base StakingInterface
*/
contract BaseStakingInterface {

    address public immutable stakingInterfaceAddress;
    NuCypherToken public immutable token;
    StakingEscrow public immutable escrow;
    PolicyManager public immutable policyManager;
    WorkLock public immutable workLock;

    /**
    * @notice Constructor sets addresses of the contracts
    * @param _token Token contract
    * @param _escrow Escrow contract
    * @param _policyManager PolicyManager contract
    * @param _workLock WorkLock contract
    */
    constructor(
        NuCypherToken _token,
        StakingEscrow _escrow,
        PolicyManager _policyManager,
        WorkLock _workLock
    ) {
        require(_token.totalSupply() > 0 &&
            _escrow.secondsPerPeriod() > 0 &&
            _policyManager.secondsPerPeriod() > 0);
        token = _token;
        escrow = _escrow;
        policyManager = _policyManager;
        workLock = _workLock;
        stakingInterfaceAddress = address(this);
    }

    /**
    * @dev Checks executing through delegate call
    */
    modifier onlyDelegateCall()
    {
        require(stakingInterfaceAddress != address(this));
        _;
    }

    /**
    * @dev Checks the existence of the worklock contract
    */
    modifier workLockSet()
    {
        require(address(workLock) != address(0));
        _;
    }

}


/**
* @notice Interface for accessing main contracts from a staking contract
* @dev All methods must be stateless because this code will be executed by delegatecall call, use immutable fields.
* @dev |v1.7.1|
*/
contract StakingInterface is BaseStakingInterface {

    event DepositedAsStaker(address indexed sender, uint256 value, uint16 periods);
    event WithdrawnAsStaker(address indexed sender, uint256 value);
    event DepositedAndIncreased(address indexed sender, uint256 index, uint256 value);
    event LockedAndCreated(address indexed sender, uint256 value, uint16 periods);
    event LockedAndIncreased(address indexed sender, uint256 index, uint256 value);
    event Divided(address indexed sender, uint256 index, uint256 newValue, uint16 periods);
    event Merged(address indexed sender, uint256 index1, uint256 index2);
    event Minted(address indexed sender);
    event PolicyFeeWithdrawn(address indexed sender, uint256 value);
    event MinFeeRateSet(address indexed sender, uint256 value);
    event ReStakeSet(address indexed sender, bool reStake);
    event WorkerBonded(address indexed sender, address worker);
    event Prolonged(address indexed sender, uint256 index, uint16 periods);
    event WindDownSet(address indexed sender, bool windDown);
    event SnapshotSet(address indexed sender, bool snapshotsEnabled);
    event Bid(address indexed sender, uint256 depositedETH);
    event Claimed(address indexed sender, uint256 claimedTokens);
    event Refund(address indexed sender, uint256 refundETH);
    event BidCanceled(address indexed sender);
    event CompensationWithdrawn(address indexed sender);

    /**
    * @notice Constructor sets addresses of the contracts
    * @param _token Token contract
    * @param _escrow Escrow contract
    * @param _policyManager PolicyManager contract
    * @param _workLock WorkLock contract
    */
    constructor(
        NuCypherToken _token,
        StakingEscrow _escrow,
        PolicyManager _policyManager,
        WorkLock _workLock
    )
        BaseStakingInterface(_token, _escrow, _policyManager, _workLock)
    {
    }

    /**
    * @notice Bond worker in the staking escrow
    * @param _worker Worker address
    */
    function bondWorker(address _worker) public onlyDelegateCall {
        escrow.bondWorker(_worker);
        emit WorkerBonded(msg.sender, _worker);
    }

    /**
    * @notice Set `reStake` parameter in the staking escrow
    * @param _reStake Value for parameter
    */
    function setReStake(bool _reStake) public onlyDelegateCall {
        escrow.setReStake(_reStake);
        emit ReStakeSet(msg.sender, _reStake);
    }

    /**
    * @notice Deposit tokens to the staking escrow
    * @param _value Amount of token to deposit
    * @param _periods Amount of periods during which tokens will be locked
    */
    function depositAsStaker(uint256 _value, uint16 _periods) public onlyDelegateCall {
        require(token.balanceOf(address(this)) >= _value);
        token.approve(address(escrow), _value);
        escrow.deposit(address(this), _value, _periods);
        emit DepositedAsStaker(msg.sender, _value, _periods);
    }

    /**
    * @notice Deposit tokens to the staking escrow
    * @param _index Index of the sub-stake
    * @param _value Amount of tokens which will be locked
    */
    function depositAndIncrease(uint256 _index, uint256 _value) public onlyDelegateCall {
        require(token.balanceOf(address(this)) >= _value);
        token.approve(address(escrow), _value);
        escrow.depositAndIncrease(_index, _value);
        emit DepositedAndIncreased(msg.sender, _index, _value);
    }

    /**
    * @notice Withdraw available amount of tokens from the staking escrow to the staking contract
    * @param _value Amount of token to withdraw
    */
    function withdrawAsStaker(uint256 _value) public onlyDelegateCall {
        escrow.withdraw(_value);
        emit WithdrawnAsStaker(msg.sender, _value);
    }

    /**
    * @notice Lock some tokens in the staking escrow
    * @param _value Amount of tokens which should lock
    * @param _periods Amount of periods during which tokens will be locked
    */
    function lockAndCreate(uint256 _value, uint16 _periods) public onlyDelegateCall {
        escrow.lockAndCreate(_value, _periods);
        emit LockedAndCreated(msg.sender, _value, _periods);
    }

    /**
    * @notice Lock some tokens in the staking escrow
    * @param _index Index of the sub-stake
    * @param _value Amount of tokens which will be locked
    */
    function lockAndIncrease(uint256 _index, uint256 _value) public onlyDelegateCall {
        escrow.lockAndIncrease(_index, _value);
        emit LockedAndIncreased(msg.sender, _index, _value);
    }

    /**
    * @notice Divide stake into two parts
    * @param _index Index of stake
    * @param _newValue New stake value
    * @param _periods Amount of periods for extending stake
    */
    function divideStake(uint256 _index, uint256 _newValue, uint16 _periods) public onlyDelegateCall {
        escrow.divideStake(_index, _newValue, _periods);
        emit Divided(msg.sender, _index, _newValue, _periods);
    }

    /**
    * @notice Merge two sub-stakes into one
    * @param _index1 Index of the first sub-stake
    * @param _index2 Index of the second sub-stake
    */
    function mergeStake(uint256 _index1, uint256 _index2) public onlyDelegateCall {
        escrow.mergeStake(_index1, _index2);
        emit Merged(msg.sender, _index1, _index2);
    }

    /**
    * @notice Mint tokens in the staking escrow
    */
    function mint() public onlyDelegateCall {
        escrow.mint();
        emit Minted(msg.sender);
    }

    /**
    * @notice Withdraw available policy fees from the policy manager to the staking contract
    */
    function withdrawPolicyFee() public onlyDelegateCall {
        uint256 value = policyManager.withdraw();
        emit PolicyFeeWithdrawn(msg.sender, value);
    }

    /**
    * @notice Set the minimum fee that the staker will accept in the policy manager contract
    */
    function setMinFeeRate(uint256 _minFeeRate) public onlyDelegateCall {
        policyManager.setMinFeeRate(_minFeeRate);
        emit MinFeeRateSet(msg.sender, _minFeeRate);
    }


    /**
    * @notice Prolong active sub stake
    * @param _index Index of the sub stake
    * @param _periods Amount of periods for extending sub stake
    */
    function prolongStake(uint256 _index, uint16 _periods) public onlyDelegateCall {
        escrow.prolongStake(_index, _periods);
        emit Prolonged(msg.sender, _index, _periods);
    }

    /**
    * @notice Set `windDown` parameter in the staking escrow
    * @param _windDown Value for parameter
    */
    function setWindDown(bool _windDown) public onlyDelegateCall {
        escrow.setWindDown(_windDown);
        emit WindDownSet(msg.sender, _windDown);
    }

    /**
    * @notice Set `snapshots` parameter in the staking escrow
    * @param _enableSnapshots Value for parameter
    */
    function setSnapshots(bool _enableSnapshots) public onlyDelegateCall {
        escrow.setSnapshots(_enableSnapshots);
        emit SnapshotSet(msg.sender, _enableSnapshots);
    }

    /**
    * @notice Bid for tokens by transferring ETH
    */
    function bid(uint256 _value) public payable onlyDelegateCall workLockSet {
        workLock.bid{value: _value}();
        emit Bid(msg.sender, _value);
    }

    /**
    * @notice Cancel bid and refund deposited ETH
    */
    function cancelBid() public onlyDelegateCall workLockSet {
        workLock.cancelBid();
        emit BidCanceled(msg.sender);
    }

    /**
    * @notice Withdraw compensation after force refund
    */
    function withdrawCompensation() public onlyDelegateCall workLockSet {
        workLock.withdrawCompensation();
        emit CompensationWithdrawn(msg.sender);
    }

    /**
    * @notice Claimed tokens will be deposited and locked as stake in the StakingEscrow contract
    */
    function claim() public onlyDelegateCall workLockSet {
        uint256 claimedTokens = workLock.claim();
        emit Claimed(msg.sender, claimedTokens);
    }

    /**
    * @notice Refund ETH for the completed work
    */
    function refund() public onlyDelegateCall workLockSet {
        uint256 refundETH = workLock.refund();
        emit Refund(msg.sender, refundETH);
    }

}