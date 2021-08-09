// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;
import "./MasterChef.sol";

contract Reinvest is Ownable {
    CakeToken public cake;
    MasterChef public masterchef;

    uint256 public HARVEST_THRESHOLD_RECAKE = 0;

    struct FeeSettings {
        uint256 total;
        uint256 _denominator;
    }
    FeeSettings public fees = FeeSettings({total: 10, _denominator: 100});

    address[] public participants_list;
    mapping(address => uint256) public isParticipating;

    // PENDING TO ADD
    mapping(uint256 => uint256) public pending_to_add;
    struct RequestToAdd {
        address user;
        uint256 pid;
        uint256 amount;
    }
    RequestToAdd[] public pending_to_add_requests;
    // PENDING TO UNCAKE
    mapping(address => bool) public is_pending_to_uncake;
    address[] public pending_to_uncake_requests;
    // PENDING TO WITHDRAW
    mapping(uint256 => uint256) public pending_to_withdraw;
    mapping(uint256 => bool) public is_pending_to_withdraw;
    mapping(uint256 => mapping(address => bool)) public is_pending_to_withdraw_user;
    uint256[] public pending_to_withdraw_pids;
    struct RequestToWithdraw {
        address user;
        uint256 pid;
    }
    RequestToWithdraw[] public pending_to_withdraw_requests;

    mapping(uint256 => uint256) public added_to_pools;
    mapping(uint256 => mapping(address => uint256)) public added_to_pools_user;

    event DeployedContract(address adr, string name);

    function doStuff() public onlyOwner {
        /** STEP 1 - HARVEST FROM RECAKE AND ADD TO RECAKE */
        // HARVEST RECAKE
        uint256 _gotRECAKE = masterchef.pendingCake(0, address(this));
        masterchef.enterStaking(0);
        uint256 _RECAKE_to_distribute = _gotRECAKE - ((_gotRECAKE * fees.total) / fees._denominator);
        added_to_pools[0] += _RECAKE_to_distribute;
        // Settle users shares
        for (uint256 i = 0; i < participants_list.length; i++) {
            address _u = participants_list[i];
            uint256 _users_cake = (_RECAKE_to_distribute * added_to_pools_user[0][_u]) / added_to_pools[0];
            added_to_pools_user[0][_u] += _users_cake;
        }
        // ADD TO RECAKE
        masterchef.enterStaking(_RECAKE_to_distribute);

        /** STEP 2 - HARVEST FROM POOLS AND ADD TO RECAKE */
        uint256 _harvestedAmount;
        uint256 _pLength = masterchef.poolLength();
        for (uint256 i = 1; i < _pLength; i++) {
            // HARVEST CAKE
            uint256 _gotCAKE = masterchef.pendingCake(i, address(this));
            if (_gotCAKE < HARVEST_THRESHOLD_RECAKE) continue;
            masterchef.deposit(i, 0);
            _harvestedAmount += _gotCAKE;
            added_to_pools[0] += _gotCAKE;
            uint256 _pool_amount = added_to_pools[i];
            // Settle users shares
            for (uint256 j = 0; j < participants_list.length; j++) {
                address _u = participants_list[j];
                uint256 _users_cake = (_pool_amount * added_to_pools_user[i][_u]) / added_to_pools[i];
                added_to_pools_user[0][_u] += _users_cake;
            }
        }
        // ADD TO RECAKE
        masterchef.enterStaking(_harvestedAmount);

        /** STEP 3 - ADD PENDING TO POOLS */
        for (uint256 i = 0; i < pending_to_add_requests.length; i++) {
            RequestToAdd storage _r = pending_to_add_requests[i];
            if (pending_to_add[_r.pid] > 0) {
                masterchef.deposit(_r.pid, pending_to_add[_r.pid]);
                added_to_pools[_r.pid] += pending_to_add[_r.pid];
                delete pending_to_add[_r.pid];
            }
            added_to_pools_user[_r.pid][_r.user] += _r.amount;
        }
        delete pending_to_add_requests;

        /** STEP 4 - UNCAKE PENDING TO USERS */
        // Calculate total to uncake
        uint256 _amount_to_uncake_total;
        for (uint256 i = 0; i < pending_to_uncake_requests.length; i++) _amount_to_uncake_total += added_to_pools_user[0][pending_to_uncake_requests[i]];
        // Uncake
        masterchef.leaveStaking(_amount_to_uncake_total);
        // Distribute
        for (uint256 i = 0; i < pending_to_uncake_requests.length; i++) {
            address _u = pending_to_uncake_requests[i];
            cake.transfer(_u, added_to_pools_user[0][_u]);
            added_to_pools[0] -= added_to_pools_user[0][_u];
            delete added_to_pools_user[0][_u];
        }
        delete pending_to_uncake_requests;

        /** STEP 5 - WITHDRAW PENDING TO USERS */
        // Calculate totals to withdraw
        for (uint256 i = 0; i < pending_to_withdraw_requests.length; i++) {
            RequestToWithdraw storage _r = pending_to_withdraw_requests[i];
            pending_to_withdraw[_r.pid] += added_to_pools_user[_r.pid][_r.user];
        }
        // Withdraw them
        for (uint256 i = 0; i < pending_to_withdraw_pids.length; i++) {
            uint256 _pid = pending_to_withdraw_pids[i];
            masterchef.withdraw(_pid, pending_to_withdraw[_pid]);
            added_to_pools[_pid] -= pending_to_withdraw[_pid];
            delete pending_to_withdraw[_pid];
        }
        delete pending_to_withdraw_pids;
        // Distribute them
        for (uint256 i = 0; i < pending_to_withdraw_requests.length; i++) {
            RequestToWithdraw storage _r = pending_to_withdraw_requests[i];
            (IBEP20 _lp,,,) = masterchef.poolInfo(_r.pid);
            _lp.transfer(_r.user, added_to_pools_user[_r.pid][_r.user]);
            delete added_to_pools_user[_r.pid][_r.user];
        }
        delete pending_to_add_requests;
    }

    function requestAdd(uint256 _pid, uint256 _amount) public {
        require(_pid != 0, "no");
        (IBEP20 _lp,,,) = masterchef.poolInfo(_pid);
        _lp.transferFrom(msg.sender, address(this), _amount);
        if (allowanceToMasterchef(_pid) == 0) approveToMasterchef(_pid);
        pending_to_add[_pid] += _amount;
        pending_to_add_requests.push(RequestToAdd({
            user: msg.sender,
            pid: _pid,
            amount: _amount
        }));
    }

    function requestUncake() public {
        require(added_to_pools_user[0][msg.sender] > 0, "You have nothing to uncake");
        require(!is_pending_to_uncake[msg.sender], "You already requested uncake");
        pending_to_uncake_requests.push(msg.sender);
        is_pending_to_uncake[msg.sender] = true;
    }

    function requestWithdraw(uint256 _pid) public {
        require(_pid != 0, "no");
        require(added_to_pools_user[_pid][msg.sender] > 0, "You have nothing to withdraw from this pool");
        require(!is_pending_to_withdraw_user[_pid][msg.sender], "You already requested to withdraw from this pool");
        pending_to_withdraw_requests.push(RequestToWithdraw({
            user: msg.sender,
            pid: _pid
        }));
        if (!is_pending_to_withdraw[_pid]) {
            pending_to_withdraw_pids.push(_pid);
            is_pending_to_withdraw[_pid] = true;
        }
        is_pending_to_withdraw_user[_pid][msg.sender] = true;
    }

    function seeCakeBalance() public view returns(uint256) {
        return cake.balanceOf(address(this));
    }
    function seeANYBalance(IBEP20 _TKN) public view returns(uint256) {
        return _TKN.balanceOf(address(this));
    }
    function seeBlockNumber() public view returns (uint256) {
        return block.number;
    }
    function seeBlockTimestamp() public view returns (uint256) {
        return block.timestamp;
    }
    function seePending(uint256 _pid, address _user) public view returns (uint256) {
        uint256 _pending = masterchef.pendingCake(_pid, address(this));
        if (_pid == 0) _pending -= (_pending * fees.total) / fees._denominator;
        return (_pending * added_to_pools_user[_pid][_user]) / added_to_pools[_pid];
    }
    function extractCake(uint256 _amount) public onlyOwner {
        cake.transfer(msg.sender, _amount == 0 ? cake.balanceOf(address(this)) : _amount);
    }

    // Well, guess... Thank you kind sir?
    function approveToMasterchef(uint256 _pid) public {
        (IBEP20 _lp,,,) = masterchef.poolInfo(_pid);
        _lp.approve(address(masterchef), ~uint256(0));
    }
    function allowanceToMasterchef(uint256 _pid) public view returns (uint256) {
        (IBEP20 _lp,,,) = masterchef.poolInfo(_pid);
        return _lp.allowance(address(this), address(masterchef));
    }
    constructor(MasterChef _masterchef) {
        masterchef = _masterchef;
        cake = masterchef.cake();
        approveToMasterchef(0);
    }
}