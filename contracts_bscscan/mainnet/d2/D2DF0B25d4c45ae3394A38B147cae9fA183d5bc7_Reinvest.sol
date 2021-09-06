/**
 *Submitted for verification at BscScan.com on 2021-09-06
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

interface IMasterChef {
    struct UserInfo {
        uint256 amount;
        uint256 rewardDebt;
    }

    struct PoolInfo {
        IBEP20 lpToken;
        uint256 allocPoint;
        uint256 lastRewardBlock;
        uint256 accCakePerShare;
    }

    function poolInfo(uint256 _pid) external view returns (PoolInfo memory);

    function userInfo(uint256 _pid, address _user) external view returns (UserInfo memory);

    function cake() external view returns (IBEP20);

    function poolLength() external view returns (uint256);

    function cakePerBlock() external view returns (uint256);

    function totalAllocPoint() external view returns (uint256);

    function pendingCake(uint256 _pid, address _user) external view returns (uint256);

    function deposit(uint256 _pid, uint256 _amount) external;

    function withdraw(uint256 _pid, uint256 _amount) external;

    function enterStaking(uint256 _amount) external;

    function leaveStaking(uint256 _amount) external;
}

interface IBEP20 {
    function totalSupply() external view returns (uint256);

    function decimals() external view returns (uint8);

    function symbol() external view returns (string memory);

    function name() external view returns (string memory);

    function getOwner() external view returns (address);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address _owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

abstract contract Ownable {
    address public owner;
    event TransferOwnership(address indexed previousOwner, address indexed newOwner);

    modifier restricted() {
        require(msg.sender == owner, 'This function is restricted to owner');
        _;
    }

    function getOwner() public view returns (address) {
        return owner;
    }

    function transferOwnership(address _newOwner) public restricted {
        require(_newOwner != address(0), 'Invalid address: should not be 0x0');
        emit TransferOwnership(owner, _newOwner);
        owner = _newOwner;
    }

    constructor() {
        owner = msg.sender;
        emit TransferOwnership(address(0), msg.sender);
    }
}

contract Reinvest is Ownable {
    IBEP20 public cake;
    IMasterChef public masterchef;

    uint256 public HARVEST_THRESHOLD = 1;
    uint256 public MIN_CPB_USER = 1;

    struct FeeSettings {
        uint256 total;
        uint256 _denominator;
    }
    FeeSettings public fees = FeeSettings({total: 10, _denominator: 100});

    address[] public participants;
    mapping(uint256 => address[]) public participantsOfPool;
    mapping(address => bool) public isParticipating;

    mapping(uint256 => uint256) public addedToPool;
    mapping(uint256 => uint256) public rewardedFromPool;
    mapping(uint256 => mapping(address => uint256)) public addedToPoolByUser;

    uint256 _harvestedAmount;
    uint256 _gotCAKE_S;
    uint256 public _currentProcessingIndex;
    uint256 public _CPR;

    event Processing(bool indexed finished);
    event Deposit(uint256 indexed pid, address indexed user, uint256 amount);
    event Withdraw(uint256 indexed pid, address indexed user, uint256 amount, uint256 cakeAmount);
    event LeaveStaking(address indexed user, uint256 amount);

    modifier notInProcessing() {
        require(_currentProcessingIndex == 0, 'Reinvest is now in processing that takes a bit too long. Please try again after several minutes');
        _;
    }

    function processStaking(uint256 _gas) internal {
        // track used gas and exit the loop if limit is reached
        uint256 gasUsed;
        uint256 gasLeft = gasleft();
        // HARVEST CAKE if didn't yet
        if (_gotCAKE_S == 0) {
            _gotCAKE_S = cake.balanceOf(address(this));
            masterchef.enterStaking(0);
            _gotCAKE_S = cake.balanceOf(address(this)) + rewardedFromPool[0] - _gotCAKE_S;
            delete rewardedFromPool[0];
            _gotCAKE_S -= ((_gotCAKE_S * fees.total) / fees._denominator);
            _harvestedAmount += _gotCAKE_S;
            addedToPool[0] += _gotCAKE_S;
        }
        gasUsed += gasLeft - gasleft();
        gasLeft = gasleft();
        // Settle users cake staking shares
        for (; _CPR < participants.length && gasUsed < _gas; _CPR++) {
            address _u = participants[_CPR];
            if (addedToPoolByUser[0][_u] == 0) continue;
            addedToPoolByUser[0][_u] += (_gotCAKE_S * addedToPoolByUser[0][_u]) / addedToPool[0];
            gasUsed += gasLeft - gasleft();
            gasLeft = gasleft();
        }
        // reset temporary data if finished
        if (_CPR == participants.length) {
            _CPR = 0;
            _gotCAKE_S = 0;
        }
    }

    function processPool(uint256 _pid) internal {
        // CHECK HARVESTABLE AMOUNT
        if (masterchef.pendingCake(_pid, address(this)) + rewardedFromPool[_pid] < HARVEST_THRESHOLD) return;
        // HARVEST CAKE
        uint256 _gotCAKE = cake.balanceOf(address(this));
        masterchef.deposit(_pid, 0);
        _gotCAKE = cake.balanceOf(address(this)) + rewardedFromPool[_pid] - _gotCAKE;
        delete rewardedFromPool[_pid];
        _harvestedAmount += _gotCAKE;
        addedToPool[0] += _gotCAKE;
        // Settle users cake staking shares
        for (uint256 j = 0; j < participantsOfPool[_pid].length; j++) {
            address _u = participantsOfPool[_pid][j];
            uint256 _users_cake = (_gotCAKE * addedToPoolByUser[_pid][_u]) / addedToPool[_pid];
            addedToPoolByUser[0][_u] += _users_cake;
        }
    }

    function process(uint256 _gas) public restricted returns (bool finished) {
        uint256 _pLength = masterchef.poolLength();
        uint256 gasUsed;
        uint256 gasLeft = gasleft();
        // HARVEST AND DISTRIBUTE CAKE FROM CAKE STAKING
        if (_currentProcessingIndex == 0 || (_currentProcessingIndex == 1 && _CPR > 0)) {
            _currentProcessingIndex = 1;
            processStaking(_gas);
            gasUsed += gasLeft - gasleft();
            gasLeft = gasleft();
        }
        // HARVEST AND DISTRIBUTE CAKE FROM POOLS
        for (; _currentProcessingIndex < _pLength && gasUsed < _gas; _currentProcessingIndex++) {
            processPool(_currentProcessingIndex);
            gasUsed += gasLeft - gasleft();
            gasLeft = gasleft();
        }
        // ENTER STAKING WITH HARVESTED AMOUNTS
        if (_currentProcessingIndex == _pLength) {
            masterchef.enterStaking(_harvestedAmount);
            _harvestedAmount = 0;
            _currentProcessingIndex = 0;
            finished = true;
        }
        emit Processing(finished);
    }

    function _isParticipatingInPool(uint256 _pid, address _user) public view returns (bool p, uint256 i) {
        for (i = 0; i < participantsOfPool[_pid].length; i++) if (participantsOfPool[_pid][i] == _user) return (true, i);
    }

    function _isParticipating(address _user) public view returns (bool p, uint256 i) {
        for (i = 0; i < participants.length; i++) if (participants[i] == _user) return (true, i);
    }

    function _removeParticipantFromPool(uint256 _pid, address _user) internal {
        (bool _participating, uint256 i) = _isParticipatingInPool(_pid, _user);
        require(_participating, 'ERROR: NOT_PARTICIPATING_IN_POOL');
        participantsOfPool[_pid][i] = participantsOfPool[_pid][participantsOfPool[_pid].length - 1];
        participantsOfPool[_pid].pop();
    }

    function _removeParticipant(address _user) internal {
        (bool _participating, uint256 i) = _isParticipating(_user);
        require(_participating, 'ERROR: NOT_PARTICIPATING');
        participants[i] = participants[participants.length - 1];
        participants.pop();
    }

    function _checkStakedAmount(uint256 _pid, uint256 _amount) public view returns (uint256 users_cake_per_block) {
        uint256 _cakePerBlock = masterchef.cakePerBlock();
        uint256 _totalAllocPoint = masterchef.totalAllocPoint();
        IMasterChef.PoolInfo memory _pool = masterchef.poolInfo(_pid);
        uint256 _totalLp = _pool.lpToken.balanceOf(address(masterchef));
        return (_cakePerBlock * _amount * _pool.allocPoint) / (_totalAllocPoint * _totalLp);
    }

    function deposit(uint256 _pid, uint256 _amount) public notInProcessing {
        // Validate data
        require(_pid != 0, 'adding straight to CAKE pool is forbidden');
        require(_amount > 0, 'amount cannot be zero');
        IMasterChef.PoolInfo memory _pool = masterchef.poolInfo(_pid);
        require(_pool.allocPoint > 0, 'this pool is inactive');
        // Deposit amount and track harvested cake
        _pool.lpToken.transferFrom(msg.sender, address(this), _amount); // Take LP
        if (allowanceToMasterchef(_pid) == 0) approveToMasterchef(_pid); // Approve this lp to masterchef if didn't yet
        uint256 _gotCAKE = cake.balanceOf(address(this));
        masterchef.deposit(_pid, _amount);
        _gotCAKE = cake.balanceOf(address(this)) - _gotCAKE;
        rewardedFromPool[_pid] += _gotCAKE;
        // Update info in storage
        addedToPool[_pid] += _amount;
        if (addedToPoolByUser[_pid][msg.sender] == 0) {
            require(_checkStakedAmount(_pid, _amount) >= MIN_CPB_USER, 'staked amount is too low');
            participantsOfPool[_pid].push(msg.sender); // Add to pool participants list if needed
        }
        addedToPoolByUser[_pid][msg.sender] += _amount;
        // Add to general participants list if needed
        if (!isParticipating[msg.sender]) {
            isParticipating[msg.sender] = true;
            participants.push(msg.sender);
        }
        emit Deposit(_pid, msg.sender, _amount);
    }

    function withdraw(uint256 _pid) public notInProcessing {
        // Validate data
        require(_pid != 0, 'for withdrawing CAKE use leaveStaking()');
        uint256 _added_by_user = addedToPoolByUser[_pid][msg.sender];
        require(_added_by_user > 0, 'you dont have anything to withdraw from this pool');
        // Withdraw amount and track harvested cake
        uint256 _gotCAKE = cake.balanceOf(address(this));
        masterchef.withdraw(_pid, _added_by_user);
        _gotCAKE = cake.balanceOf(address(this)) - _gotCAKE;
        rewardedFromPool[_pid] += _gotCAKE;
        uint256 _users_pending_cake = (rewardedFromPool[_pid] * _added_by_user) / addedToPool[_pid];
        rewardedFromPool[_pid] -= _users_pending_cake;
        masterchef.poolInfo(_pid).lpToken.transfer(msg.sender, _added_by_user); // Send LP
        cake.transfer(msg.sender, _users_pending_cake); // Send pending cake
        // Update info in storage
        addedToPool[_pid] -= _added_by_user;
        delete addedToPoolByUser[_pid][msg.sender];
        // Remove from pool participants list
        _removeParticipantFromPool(_pid, msg.sender);
        emit Withdraw(_pid, msg.sender, _added_by_user, _users_pending_cake);
    }

    function leaveStaking() public notInProcessing {
        // Validate data
        require(addedToPool[0] > 0, 'CAKE STAKING POOL IS EMPTY');
        uint256 _added_by_user = addedToPoolByUser[0][msg.sender];
        require(_added_by_user > 0, 'you dont have anything to withdraw from this pool');
        // Withdraw amount and track harvested cake
        uint256 _gotCAKE = cake.balanceOf(address(this));
        masterchef.leaveStaking(_added_by_user);
        _gotCAKE = cake.balanceOf(address(this)) - _added_by_user - _gotCAKE;
        rewardedFromPool[0] += _gotCAKE;
        uint256 _users_pending_cake = (rewardedFromPool[0] * _added_by_user) / addedToPool[0];
        rewardedFromPool[0] -= _users_pending_cake;
        _users_pending_cake -= (_users_pending_cake * fees.total) / fees._denominator;
        cake.transfer(msg.sender, _added_by_user + _users_pending_cake); // Send CAKE
        addedToPool[0] -= _added_by_user;
        delete addedToPoolByUser[0][msg.sender];
        // Remove from general participants list if needed
        uint256 _pLength = masterchef.poolLength();
        for (uint256 i = 1; i < _pLength; i++) if (addedToPoolByUser[i][msg.sender] > 0) return;
        _removeParticipant(msg.sender);
        isParticipating[msg.sender] = false;
        emit LeaveStaking(msg.sender, _added_by_user + _users_pending_cake);
    }

    function seeCakeBalance() public view returns (uint256) {
        return cake.balanceOf(address(this));
    }

    function seeANYBalance(IBEP20 _TKN) public view returns (uint256) {
        return _TKN.balanceOf(address(this));
    }

    function seeBlockNumber() public view returns (uint256) {
        return block.number;
    }

    function seeBlockTimestamp() public view returns (uint256) {
        return block.timestamp;
    }

    function seePending(uint256 _pid, address _user) public view returns (uint256) {
        if (addedToPool[_pid] == 0) return 0;
        uint256 _added_by_user = addedToPoolByUser[_pid][_user];
        uint256 _pending_cake = masterchef.pendingCake(_pid, address(this)) + rewardedFromPool[_pid];
        if (_pid == 0) _pending_cake -= (_pending_cake * fees.total) / fees._denominator;
        return (_pending_cake * _added_by_user) / addedToPool[_pid];
    }

    function getParticipants() public view returns (address[] memory p) {
        p = participants;
    }

    function extractCake(uint256 _amount) public restricted notInProcessing {
        uint256 _mustPreserve;
        uint256 _pLength = masterchef.poolLength();
        for (uint256 i = 0; i < _pLength; i++) _mustPreserve += rewardedFromPool[i];
        uint256 _canExtract = cake.balanceOf(address(this)) - _mustPreserve;
        if (_amount == 0) cake.transfer(msg.sender, _canExtract);
        else {
            require(_amount <= _canExtract, 'Too much - some of this cake is not yours, dear owner');
            cake.transfer(msg.sender, _amount);
        }
    }

    function setFees(uint256 _total, uint256 _denominator) public restricted notInProcessing {
        require(_denominator != 0 && _total < _denominator / 4);
        fees = FeeSettings(_total, _denominator);
    }

    function setHarvestThreshold(uint256 _amount) public restricted {
        HARVEST_THRESHOLD = _amount;
    }

    function setMinCakePerBlock(uint256 _amount) public restricted {
        MIN_CPB_USER = _amount;
    }

    // Well, guess... Thank you kind sir?
    function approveToMasterchef(uint256 _pid) public {
        masterchef.poolInfo(_pid).lpToken.approve(address(masterchef), ~uint256(0));
    }

    function allowanceToMasterchef(uint256 _pid) public view returns (uint256) {
        return masterchef.poolInfo(_pid).lpToken.allowance(address(this), address(masterchef));
    }

    constructor(IMasterChef _masterchef) {
        masterchef = _masterchef;
        cake = masterchef.cake();
        approveToMasterchef(0);
    }
}