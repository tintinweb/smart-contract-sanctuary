/**
 *Submitted for verification at Etherscan.io on 2021-08-25
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

interface vote {
    struct VoteData {
        bool is_open;
        bool is_executed;
        uint start_date;
        uint snapshot_block;
        uint support_required;
        uint min_accept_quorum;
        uint yea;
        uint nay;
        uint voting_power;
    }
    
    function getVote(uint vote_id) external view returns (VoteData memory);
    function getVoterState(uint vote_id, address voter) external view returns (uint);
}

interface ve {
    function balanceOfAt(address owner, uint block_number) external view returns (uint);
}

interface erc20 {
    function transfer(address recipient, uint amount) external returns (bool);
    function balanceOf(address) external view returns (uint);
    function transferFrom(address sender, address recipient, uint amount) external returns (bool);
}

contract BribeV2Vote {
    vote constant VOTE = vote(0xE478de485ad2fe566d49342Cbd03E49ed7DB3356);
    ve constant veCRV = ve(0x5f3b5DfEb7B28CDbD7FAba78963EE202a494e2A2);
    uint constant desired_vote = 1;
    
    // vote_id => reward_token => reward_amount
    mapping(uint => mapping(address => uint)) public reward_amount;
    mapping(uint => uint) public snapshot_block;
    mapping(uint => uint) public yeas;
    mapping(uint => mapping(address => mapping(address => uint))) given_rewards;
    mapping(uint => mapping(address => uint)) public vote_states;
    mapping(uint => mapping(address => mapping(address => bool))) public has_claimed;
    
    mapping(uint => address[]) _rewards_per_vote;
    mapping(uint => mapping(address => bool)) _rewards_for_vote_exists;
    
    event Bribe(address indexed briber, uint vote_id, address reward_token, uint amount);
    event Claim(address indexed claimant, uint vote_id, address reward_token, uint amount);
    
    function rewards_per_vote(uint vote_id) external view returns (address[] memory) {
        return _rewards_per_vote[vote_id];
    }
    
    function add_reward_amount(uint vote_id, address reward_token, uint amount) external returns (bool) {
        vote.VoteData memory _vote = VOTE.getVote(vote_id);
        uint _vote_state = vote_states[vote_id][reward_token];
        require(_vote_state == 0);
        _safeTransferFrom(reward_token, msg.sender, address(this), amount);
        reward_amount[vote_id][reward_token] += amount;
        given_rewards[vote_id][reward_token][msg.sender] += amount;
        snapshot_block[vote_id] = _vote.snapshot_block;
        if (!_rewards_for_vote_exists[vote_id][reward_token]) {
            _rewards_for_vote_exists[vote_id][reward_token] = true;
            _rewards_per_vote[vote_id].push(reward_token);
        }
        emit Bribe(msg.sender, vote_id, reward_token, amount);
        return true;
    }
    
    function estimate_bribe(uint vote_id, address reward_token, address claimant) external view returns (uint) {
        vote.VoteData memory _vote = VOTE.getVote(vote_id);
        uint _vecrv = veCRV.balanceOfAt(claimant, _vote.snapshot_block);
        if (VOTE.getVoterState(vote_id, claimant) == desired_vote) {
            return reward_amount[vote_id][reward_token] * _vecrv / _vote.yea;
        } else {
            return reward_amount[vote_id][reward_token] * _vecrv / (_vote.yea + _vecrv);
        }
    }
    
    function _update_vote_state(uint vote_id, address reward_token) internal returns (uint) {
        vote.VoteData memory _vote = VOTE.getVote(vote_id);
        require(!_vote.is_open);
        uint total_vecrv = _vote.yea + _vote.nay;
        bool has_quorum = total_vecrv * 10**18 / _vote.voting_power > _vote.min_accept_quorum;
        bool has_support = _vote.yea * 10**18 / total_vecrv > _vote.support_required;
        
        if (has_quorum && has_support) {
            vote_states[vote_id][reward_token] = 1;
            yeas[vote_id] = _vote.yea;
            return 1;
        } else {
            vote_states[vote_id][reward_token] = 2;
            return 2;
        }
    }
    
    function withdraw_reward(uint vote_id, address reward_token, address claimant) external returns (bool) {
        uint _vote_state = vote_states[vote_id][reward_token];
        if (_vote_state == 0) {
            _vote_state = _update_vote_state(vote_id, reward_token);
        }
        require(_vote_state == 2);
        uint _amount = given_rewards[vote_id][reward_token][claimant];
        given_rewards[vote_id][reward_token][claimant] = 0;
        reward_amount[vote_id][reward_token] -= _amount;
        _safeTransfer(reward_token, claimant, _amount);
        return true;
    }
    
    function claim_reward(uint vote_id, address reward_token, address claimant) external returns (bool) {
        return _claim_reward(vote_id, reward_token, claimant);
    }
    
    function claim_reward(uint vote_id, address reward_token) external returns (bool) {
        return _claim_reward(vote_id, reward_token, msg.sender);
    }
    
    function _claim_reward(uint vote_id, address reward_token, address claimant) internal returns (bool) {
        uint _vote_state = vote_states[vote_id][reward_token];
        if (_vote_state == 0) {
            _vote_state = _update_vote_state(vote_id, reward_token);
        }
        require(_vote_state == 1);
        require(!has_claimed[vote_id][reward_token][claimant]);
        require(VOTE.getVoterState(vote_id, claimant) == desired_vote);
        has_claimed[vote_id][reward_token][claimant] = true;
        
        uint _vecrv = veCRV.balanceOfAt(claimant, snapshot_block[vote_id]);
        uint _amount = reward_amount[vote_id][reward_token] * _vecrv / yeas[vote_id];
        _safeTransfer(reward_token, claimant, _amount);
        emit Bribe(claimant, vote_id, reward_token, _amount);
        return true;
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