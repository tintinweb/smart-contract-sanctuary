/**
 *Submitted for verification at Etherscan.io on 2021-05-25
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

contract CORXLPFarmR {
    address public owner;
    IERC20 public TKN;

    struct Stake {
        uint256 amount;
        uint256 debt;
        uint32 started;
    }

    struct Program {
        IERC20 LPTKN;
        uint256 M; // Multiplier. Default is 10 == 100% APY
        uint256 B; // LP amount per 1e9 CORX in that LP (all in wei). EXAMPLE: at FCORX/ETH (Rinkeby) it's 12247509951 (11 May 2021)
        uint32 start;
        uint32 finish;
    }
    uint256 public constant k = 3171; // 10% (base APY unit) APY == x0.000,274 per day = x0.000,000,003,171 per second

    Program[] public programs;
    mapping(uint256 => mapping(address => Stake)) public stakeOf;

    event Staked(address indexed sender, uint256 amount, uint256 debt);
    event Harvested(address indexed sender, uint256 harvest);
    event Unstaked(address indexed sender, uint256 amount, uint256 harvest);

    modifier restricted {
        require(msg.sender == owner);
        _;
    }

    function addProgram(IERC20 _LPTKN, uint256 _multiplier, uint256 _baseratio, uint32 _start, uint32 _finish) public restricted {
        programs.push(Program({LPTKN: _LPTKN, M: _multiplier, B: _baseratio, start: _start, finish: _finish}));
    }

    function getPending(uint256 _pid, address _user, uint32 _to) public view returns (uint256) {
        Program storage _p = programs[_pid];
        Stake storage _s = stakeOf[_pid][_user];
        if (_to > _p.finish) _to = _p.finish;
        return _s.debt + ((_p.M * k * (_to - _s.started) * _s.amount * 2) / (_p.B * 1e4));
    }

    function getPending(uint256 _pid, address _user) public view returns (uint256) {
        return getPending(_pid, _user, uint32(block.timestamp));
    }

    function getPending(uint256 _pid) public view returns (uint256) {
        return getPending(_pid, msg.sender);
    }

    function pLength() public view returns (uint256) {
        return programs.length;
    }

    function stake(uint256 _pid, uint256 _amount) public {
        require(_pid < pLength() && _amount > 0);
        Program storage _p = programs[_pid];
        require(_p.start <= block.timestamp && block.timestamp < _p.finish);
        require(_p.LPTKN.transferFrom(msg.sender, address(this), _amount));
        Stake storage _s = stakeOf[_pid][msg.sender];
        _s.debt = getPending(_pid);
        _s.amount += _amount;
        _s.started = uint32(block.timestamp);
        emit Staked(msg.sender, _amount, _s.debt);
    }

    function unstake(uint256 _pid) public {
        require(_pid < pLength(), "invalid pid");
        Stake storage _s = stakeOf[_pid][msg.sender];
        require(_s.amount > 0, "nothing staked");
        programs[_pid].LPTKN.transfer(msg.sender, _s.amount);
        uint256 _toSend = getPending(_pid);
        if (_toSend > 0) TKN.transfer(msg.sender, _toSend);
        emit Unstaked(msg.sender, _s.amount, _toSend);
        delete stakeOf[_pid][msg.sender];
    }

    function harvest(uint256 _pid) public {
        Stake storage _s = stakeOf[_pid][msg.sender];
        uint256 _toSend = getPending(_pid);
        require(_toSend > 0, "nothing to harvest");
        TKN.transfer(msg.sender, _toSend);
        _s.debt = 0;
        uint32 _f = programs[_pid].finish;
        _s.started = uint32(block.timestamp < _f ? block.timestamp : _f);
        emit Harvested(msg.sender, _toSend);
    }

    function infoBundle(address _user) public view returns (Program[] memory pp, Stake[] memory ss, uint256[] memory all, uint256[] memory bal) {
        pp = programs;
        uint256 _l = pp.length;
        ss = new Stake[](_l);
        all = new uint256[](_l);
        bal = new uint256[](_l);
        for (uint256 i = 0; i < _l; i++) {
            ss[i] = stakeOf[i][_user];
            all[i] = pp[i].LPTKN.allowance(_user, address(this));
            bal[i] = pp[i].LPTKN.balanceOf(_user);
        }
    }

    function take(IERC20 _TKN, uint256 _amount) public restricted {
        _TKN.transfer(msg.sender, _amount > 0 ? _amount : _TKN.balanceOf(address(this)));
    }

    function transferOwnership(address _owner) public restricted {
        owner = _owner;
    }

    constructor(IERC20 _TKN) {
        owner = msg.sender;
        TKN = _TKN;
    }
}