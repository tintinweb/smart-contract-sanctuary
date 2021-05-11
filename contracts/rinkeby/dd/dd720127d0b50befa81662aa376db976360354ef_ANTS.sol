// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import './Operator.sol';
import './ERC20.sol';
import './IERC20.sol';

contract ANTS is ERC20, Operator {
    IERC20 public _usdt = IERC20(0x1D3848897A4b493bC109B82b369826d43e9f166B);
    address public _team;
    uint256 public _reward = 10 * 1e18;
    uint256 public _totalReward;
    uint256 public _price = 1e17;
    uint256 public _swapped;
    uint256 public _maxSwap = 9500000 * 1e18;
    uint256 public _transfered;
    uint256 public _maxTransfer = 11500000 * 1e18;
    uint public _increaseNum;
    bool public _canSwap;
    bool public _canJoin = true;
    uint public _awardTime;
    mapping(address => User) public userMap;

    struct User {
        bool active;
        uint256 reward;
    }
    
    constructor(address team) public ERC20('ANTS', 'ANTS') {
        _mint(address(this), 21 * 1e6 * 1e18);
        _awardTime = block.timestamp.add(30 days);
        _team = team;
    }

    function swap(uint256 amount) public{
        require(amount>0, 'Can\'t swap 0');
        require(_canSwap && _swapped<_maxSwap, 'Can\'t swap');
        uint256 reward = amount.mul(1e18).div(_price);
        uint256 swapped = _swapped.add(reward);
        (bool flag,uint256 exceed) = swapped.trySub(_maxSwap);
        if(flag){
            swapped = _maxSwap;
            reward = reward.sub(exceed);
            amount = reward.mul(1e17).div(1e18);
        }
        _usdt.transferFrom(msg.sender, _team, amount);
        IERC20(address(this)).transfer(msg.sender, reward);
        _swapped = swapped;
        uint increaseNum = _swapped.div(500000 * 1e18);
        for(uint i=_increaseNum;i<increaseNum;i++){
            _price = _price.add(1e16);
        }
        _increaseNum = increaseNum;
    }

    function join() public{
        require(_canJoin, 'Can\'t join');
        require(!userMap[msg.sender].active, 'Joined');
        userMap[msg.sender].active = true;
    }

    function getReward() public{
        require(_reward>0&&block.timestamp>=_awardTime, 'Can\'t award');
        require(userMap[msg.sender].active, 'Didn\'t join');
        require(userMap[msg.sender].reward==0, 'Recevied');
        IERC20(address(this)).transfer(msg.sender, _reward);
        userMap[msg.sender].reward = _reward;
        _totalReward = _totalReward.add(_reward);
    }

    function transferOut(address to,uint256 amount) external onlyOperator {
        uint256 transfered = _transfered.add(amount);
        (bool flag,uint256 exceed) = transfered.trySub(_maxTransfer);
        if(flag){
            transfered = _maxTransfer;
            amount = amount.sub(exceed);
        }
        IERC20(address(this)).transfer(to, amount);
        _transfered = transfered;
    }

    function setCanSwap(bool canSwap) external onlyOperator {
        _canSwap = canSwap;
    }

    function setCanJoin(bool canJoin) external onlyOperator {
        _canJoin = canJoin;
    }

    function setReward(uint256 reward) external onlyOperator {
        _reward = reward;
    }

    function setAwardTime(uint awardTime) external onlyOperator {
        _awardTime = awardTime;
    }

    function setConf(bool canSwap, bool canJoin, uint256 reward, uint awardTime) external onlyOperator {
        _canSwap = canSwap;
        _canJoin = canJoin;
        _reward = reward;
        _awardTime = awardTime;
    }
}