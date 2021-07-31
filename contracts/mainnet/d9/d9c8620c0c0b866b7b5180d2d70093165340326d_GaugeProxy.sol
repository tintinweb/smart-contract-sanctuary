/**
 *Submitted for verification at Etherscan.io on 2021-07-31
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

library Math {
    function max(uint a, uint b) internal pure returns (uint) {
        return a >= b ? a : b;
    }
    function min(uint a, uint b) internal pure returns (uint) {
        return a < b ? a : b;
    }
}

interface erc20 {
    function totalSupply() external view returns (uint256);
    function transfer(address recipient, uint amount) external returns (bool);
    function decimals() external view returns (uint8);
    function balanceOf(address) external view returns (uint);
    function transferFrom(address sender, address recipient, uint amount) external returns (bool);
    function approve(address spender, uint value) external returns (bool);
}

interface ve {
    function locked__end(address) external view returns (uint);
    function deposit_for(address, uint) external;
}

contract Gauge {
    address constant _ibff = 0xb347132eFf18a3f63426f4988ef626d2CbE274F5;
    address constant _veibff = 0x4D0518C9136025903751209dDDdf6C67067357b1;
    address constant _vedist = 0x83893c4A42F8654c2dd4FF7b4a7cd0e33ae8C859;
    
    uint constant DURATION = 7 days;
    uint constant PRECISION = 10 ** 18;
    uint constant MAXTIME = 4 * 365 * 86400;
    
    address public immutable stake;
    address immutable distribution;
    
    uint public rewardRate;
    uint public periodFinish;
    uint public lastUpdateTime;
    uint public rewardPerTokenStored;
    
    modifier onlyDistribution() {
        require(msg.sender == distribution);
        _;
    }
    
    mapping(address => uint) public userRewardPerTokenPaid;
    mapping(address => uint) public rewards;

    uint public totalSupply;
    uint public derivedSupply;
    mapping(address => uint) public balanceOf;
    mapping(address => uint) public derivedBalances;
    
    constructor(address _stake) {
        stake = _stake;
        distribution = msg.sender;
    }

    function lastTimeRewardApplicable() public view returns (uint) {
        return Math.min(block.timestamp, periodFinish);
    }

    function rewardPerToken() public view returns (uint) {
        if (totalSupply == 0) {
            return rewardPerTokenStored;
        }
        return rewardPerTokenStored + ((lastTimeRewardApplicable() - lastUpdateTime) * rewardRate * PRECISION / derivedSupply);
    }
    
    function derivedBalance(address account) public view returns (uint) {
        uint _balance = balanceOf[account];
        uint _derived = _balance * 40 / 100;
        uint _adjusted = (totalSupply * erc20(_veibff).balanceOf(account) / erc20(_veibff).totalSupply()) * 60 / 100;
        return Math.min(_derived + _adjusted, _balance);
    }
    
    function kick(address account) public {
        uint _derivedBalance = derivedBalances[account];
        derivedSupply -= _derivedBalance;
        _derivedBalance = derivedBalance(account);
        derivedBalances[account] = _derivedBalance;
        derivedSupply += _derivedBalance;
    }

    function earned(address account) public view returns (uint) {
        return (derivedBalances[account] * (rewardPerToken() - userRewardPerTokenPaid[account]) / PRECISION) + rewards[account];
    }

    function getRewardForDuration() external view returns (uint) {
        return rewardRate * DURATION;
    }
    
    function deposit() external {
        _deposit(erc20(stake).balanceOf(msg.sender), msg.sender);
    }
    
    function deposit(uint amount) external {
        _deposit(amount, msg.sender);
    }
    
    function deposit(uint amount, address account) external {
        _deposit(amount, account);
    }
    
    function _deposit(uint amount, address account) internal updateReward(account) {
        totalSupply += amount;
        balanceOf[account] += amount;
        _safeTransferFrom(stake, account, address(this), amount);
    }
    
    function withdraw() external {
        _withdraw(balanceOf[msg.sender]);
    }

    function withdraw(uint amount) external {
        _withdraw(amount);
    }
    
    function _withdraw(uint amount) internal updateReward(msg.sender) {
        totalSupply -= amount;
        balanceOf[msg.sender] -= amount;
        _safeTransfer(stake, msg.sender, amount);
    }

    function getReward() public updateReward(msg.sender) {
        uint _reward = rewards[msg.sender];
        uint _user_lock = ve(_veibff).locked__end(msg.sender);
        uint _adj = Math.min(_reward * _user_lock / (block.timestamp + MAXTIME), _reward);
        if (_adj > 0) {
            rewards[msg.sender] = 0;
            _safeTransfer(_ibff, msg.sender, _adj);
            ve(_veibff).deposit_for(msg.sender, _adj);
            _safeTransfer(_ibff, _vedist, _reward - _adj);
        }
    }

    function exit() external {
       _withdraw(balanceOf[msg.sender]);
        getReward();
    }
    
    function notifyRewardAmount(uint amount) external onlyDistribution updateReward(address(0)) {
        if (block.timestamp >= periodFinish) {
            rewardRate = amount / DURATION;
        } else {
            uint _remaining = periodFinish - block.timestamp;
            uint _left = _remaining * rewardRate;
            rewardRate = (amount + _left) / DURATION;
        }
        
        lastUpdateTime = block.timestamp;
        periodFinish = block.timestamp + DURATION;
    }

    modifier updateReward(address account) {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = lastTimeRewardApplicable();
        if (account != address(0)) {
            rewards[account] = earned(account);
            userRewardPerTokenPaid[account] = rewardPerTokenStored;
        }
        _;
        if (account != address(0)) {
            kick(account);
        }
    }
    
    function _safeTransfer(address token, address to, uint256 value) internal {
        (bool success, bytes memory data) =
            token.call(abi.encodeWithSelector(erc20.transfer.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))));
    }
    
    function _safeTransferFrom(address token, address from, address to, uint256 value) internal {
        (bool success, bytes memory data) =
            token.call(abi.encodeWithSelector(erc20.transferFrom.selector, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))));
    }
}

contract GaugeProxy {
    address constant _ibff = 0xb347132eFf18a3f63426f4988ef626d2CbE274F5;
    address constant _veibff = 0x4D0518C9136025903751209dDDdf6C67067357b1;
    
    uint public totalWeight;
    
    address public gov;
    address public nextgov;
    uint public commitgov;
    uint public constant delay = 1 days;
    
    address[] internal _tokens;
    mapping(address => address) public gauges; // token => gauge
    mapping(address => uint) public weights; // token => weight
    mapping(address => mapping(address => uint)) public votes; // msg.sender => votes
    mapping(address => address[]) public tokenVote;// msg.sender => token
    mapping(address => uint) public usedWeights;  // msg.sender => total voting weight of user
    
    function tokens() external view returns (address[] memory) {
        return _tokens;
    }
    
    constructor() {
        gov = msg.sender;
    }
    
    modifier g() {
        require(msg.sender == gov);
        _;
    }
    
    function setGov(address _gov) external g {
        nextgov = _gov;
        commitgov = block.timestamp + delay;
    }
    
    function acceptGov() external {
        require(msg.sender == nextgov && commitgov < block.timestamp);
        gov = nextgov;
    }
    
    function reset() external {
        _reset(msg.sender);
    }
    
    function _reset(address _owner) internal {
        address[] storage _tokenVote = tokenVote[_owner];
        uint _tokenVoteCnt = _tokenVote.length;

        for (uint i = 0; i < _tokenVoteCnt; i ++) {
            address _token = _tokenVote[i];
            uint _votes = votes[_owner][_token];
            
            if (_votes > 0) {
                totalWeight -= _votes;
                weights[_token] -= _votes;
                votes[_owner][_token] = 0;
            }
        }

        delete tokenVote[_owner];
    }
    
    function poke(address _owner) public {
        address[] memory _tokenVote = tokenVote[_owner];
        uint _tokenCnt = _tokenVote.length;
        uint[] memory _weights = new uint[](_tokenCnt);
        
        uint _prevUsedWeight = usedWeights[_owner];
        uint _weight = erc20(_veibff).balanceOf(_owner);

        for (uint i = 0; i < _tokenCnt; i ++) {
            uint _prevWeight = votes[_owner][_tokenVote[i]];
            _weights[i] = _prevWeight * _weight / _prevUsedWeight;
        }

        _vote(_owner, _tokenVote, _weights);
    }
    
    function _vote(address _owner, address[] memory _tokenVote, uint[] memory _weights) internal {
        // _weights[i] = percentage * 100
        _reset(_owner);
        uint _tokenCnt = _tokenVote.length;
        uint _weight = erc20(_veibff).balanceOf(_owner);
        uint _totalVoteWeight = 0;
        uint _usedWeight = 0;

        for (uint i = 0; i < _tokenCnt; i ++) {
            _totalVoteWeight += _weights[i];
        }

        for (uint i = 0; i < _tokenCnt; i ++) {
            address _token = _tokenVote[i];
            address _gauge = gauges[_token];
            uint _tokenWeight = _weights[i] * _weight / _totalVoteWeight;

            if (_gauge != address(0x0)) {
                _usedWeight += _tokenWeight;
                totalWeight += _tokenWeight;
                weights[_token] += _tokenWeight;
                tokenVote[_owner].push(_token);
                votes[_owner][_token] = _tokenWeight;
            }
        }

        usedWeights[_owner] = _usedWeight;
    }
    
    function vote(address[] calldata _tokenVote, uint[] calldata _weights) external {
        require(_tokenVote.length == _weights.length);
        _vote(msg.sender, _tokenVote, _weights);
    }
    
    function addGauge(address _token) external g {
        require(gauges[_token] == address(0x0), "exists");
        gauges[_token] = address(new Gauge(_token));
        _tokens.push(_token);
    }
    
    function length() external view returns (uint) {
        return _tokens.length;
    }
    
    function distribute() external {
        uint _balance = erc20(_ibff).balanceOf(address(this));
        if (_balance > 0 && totalWeight > 0) {
            for (uint i = 0; i < _tokens.length; i++) {
                address _token = _tokens[i];
                address _gauge = gauges[_token];
                uint _reward = _balance * weights[_token] / totalWeight;
                if (_reward > 0) {
                    _safeTransfer(_ibff, _gauge, _reward);
                    Gauge(_gauge).notifyRewardAmount(_reward);
                }
            }
        }
    }
    
    function _safeTransfer(address token, address to, uint256 value) internal {
        (bool success, bytes memory data) =
            token.call(abi.encodeWithSelector(erc20.transfer.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))));
    }
}